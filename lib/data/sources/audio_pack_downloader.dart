import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../core/constants.dart';
import '../../core/hash_utils.dart';
import '../../core/logger.dart';
import 'audio_pack_manifest.dart';

/// 离线包下载失败分类（TECH_DOC §9.2：网络 / 校验 / 解压 / 取消 / 坏包）。
enum AudioPackDownloadFailure {
  network,
  checksum,
  archive,
  cancelled,
  badManifest,
}

/// 离线包下载异常：携带失败分类，WorkManager 任务据此决定重试语义。
class AudioPackDownloadException implements Exception {
  const AudioPackDownloadException(this.failure, this.message);

  final AudioPackDownloadFailure failure;
  final String message;

  @override
  String toString() => 'AudioPackDownloadException(${failure.name}): $message';
}

/// 离线音频包下载器（TECH_DOC §9.2）：纯 Dart 实现，不依赖 Flutter/数据库。
///
/// 职责链：拉取 manifest → HTTP Range 断点续传（.part + downloaded_size）→
/// zip SHA-256 校验 → 解压到 staging（逐文件复核）→ 原子替换 `audio/` 目录。
/// 状态行（audio_packs）由调用方（WorkManager 任务）通过仓储维护，本类只做
/// 文件系统与网络，便于用本地 HttpServer 做端到端单测。
class AudioPackDownloader {
  AudioPackDownloader({
    required this.packRootProvider,
    HttpClient? httpClient,
  }) : _http = httpClient ?? HttpClient();

  /// 词书 ID → 包根目录（`<应用私有目录>/audio_packs/<wordbookId>`）。
  final Future<Directory> Function(int wordbookId) packRootProvider;
  final HttpClient _http;

  /// 连接/响应超时：超过视为网络失败（WorkManager 退避重试，§11.2）。
  static const Duration _timeout = Duration(seconds: 30);

  /// 拉取并解析发布基址下的 manifest.json；坏包抛 [AudioPackDownloadException]。
  Future<AudioPackManifest> fetchManifest(Uri baseUri) async {
    final request = await _http
        .getUrl(baseUri.resolve('manifest.json'))
        .timeout(_timeout);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.badManifest,
        'manifest HTTP ${response.statusCode}',
      );
    }
    final body = await response.transform(utf8.decoder).join();
    try {
      return AudioPackManifest.parse(body);
    } on FormatException catch (error) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.badManifest,
        error.message,
      );
    }
  }

  /// 下载 → 校验 → 解压 → 原子替换全流程；成功后包内文件位于
  /// `<packRoot>/audio/<audioKey>.mp3`（§9.2）。
  Future<void> downloadAndInstall({
    required int wordbookId,
    required String version,
    required Uri baseUri,
    required AudioPackManifest manifest,
    required Future<void> Function(int downloadedBytes, int totalBytes)
    onProgress,
    bool Function()? isCancelled,
  }) async {
    final packDir = await packRootProvider(wordbookId);
    packDir.createSync(recursive: true);
    final downloadsDir = Directory('${packDir.path}/downloads')
      ..createSync(recursive: true);
    final partFile = File('${downloadsDir.path}/$version.part');

    await _downloadZip(
      manifest.zipUri(baseUri),
      partFile,
      manifest.zipSize,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );

    // 5. zip 整体 SHA-256 校验（TECH_DOC §9.2 第 5 条）；不一致删除 .part。
    final actualSha = Sha256Utils.fileSha256(partFile);
    if (actualSha != manifest.zipSha256) {
      partFile.deleteSync();
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.checksum,
        'zip SHA-256 不匹配：期望 ${manifest.zipSha256.substring(0, 12)}…，'
        '实际 $actualSha',
      );
    }

    // 6. 解压到 staging 并逐文件复核，全部通过后原子替换（第 6 条）。
    final staging = Directory('${packDir.path}/staging-$version');
    if (staging.existsSync()) {
      // 上次失败的残留 staging，直接清理（下载已完成，解压幂等可重来）。
      staging.deleteSync(recursive: true);
    }
    try {
      _extractAndVerify(partFile, staging, manifest);
      _installStaging(packDir, staging, version);
    } on AudioPackDownloadException {
      rethrow;
    } catch (error) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.archive,
        '解压/替换失败：$error',
      );
    }

    partFile.deleteSync();
    _cleanupDownloadsDir(downloadsDir);
  }

  /// Range 断点续传主循环（TECH_DOC §9.2 第 4 条）。
  Future<void> _downloadZip(
    Uri zipUri,
    File partFile,
    int expectedSize, {
    required Future<void> Function(int downloadedBytes, int totalBytes)
    onProgress,
    required bool Function()? isCancelled,
  }) async {
    var downloaded = partFile.existsSync() ? partFile.lengthSync() : 0;
    if (downloaded > expectedSize) {
      // 目标版本变更/上次残留超长：从头下载。
      partFile.deleteSync();
      downloaded = 0;
    }
    final raf = partFile.openSync(mode: FileMode.append);
    var lastReported = downloaded;
    try {
      while (downloaded < expectedSize) {
        _throwIfCancelled(isCancelled);
        final request = await _http.getUrl(zipUri).timeout(_timeout);
        request.headers.set(HttpHeaders.acceptHeader, 'application/octet-stream');
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$downloaded-');
        final response = await request.close().timeout(_timeout);

        if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable &&
            downloaded >= expectedSize) {
          break; // 已完整，服务端对越界 Range 返回 416。
        }
        var progressMade = false;
        if (response.statusCode == HttpStatus.partialContent) {
          // 206：从 downloaded 续传。
        } else if (response.statusCode == HttpStatus.ok) {
          // 服务端不支持 Range：整包重下（先清空已下载部分）。
          raf.truncateSync(0);
          downloaded = 0;
          await raf.setPosition(0);
        } else {
          throw AudioPackDownloadException(
            AudioPackDownloadFailure.network,
            '下载 HTTP ${response.statusCode}',
          );
        }

        await for (final chunk in response) {
          _throwIfCancelled(isCancelled);
          // FileMode.append 下 writeFrom 恒写入文件尾：206 续传直接追加；
          // 200 整包重下已先 truncate 到 0，行为等价覆盖写。
          await raf.writeFrom(chunk);
          downloaded += chunk.length;
          progressMade = true;
          if (downloaded - lastReported >=
              AppConstants.audioDownloadProgressChunkBytes) {
            await onProgress(downloaded, expectedSize);
            lastReported = downloaded;
          }
        }
        if (!progressMade && downloaded < expectedSize) {
          // 响应完成但未带来任何字节：服务端行为异常，避免 Range 空转无限循环。
          throw AudioPackDownloadException(
            AudioPackDownloadFailure.network,
            '服务端返回空响应（HTTP ${response.statusCode}）',
          );
        }
      }
      await onProgress(downloaded, expectedSize);
      _throwIfCancelled(isCancelled);
    } on AudioPackDownloadException {
      rethrow;
    } catch (error) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.network,
        '下载中断：$error',
      );
    } finally {
      await raf.close();
    }
  }

  /// 解压 zip 到 staging，并按 manifest 逐文件复核 SHA-256（§9.2 第 6 条）。
  void _extractAndVerify(
    File zipFile,
    Directory staging,
    AudioPackManifest manifest,
  ) {
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
    } catch (error) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.archive,
        'zip 解析失败：$error',
      );
    }
    for (final entry in archive) {
      if (!entry.isFile) {
        continue;
      }
      final safePath = _safeAudioPath(entry.name);
      // staging 直接存放文件（不含 audio/ 前缀），安装时整目录改名为
      // `<packRoot>/audio`，避免路径重复成 audio/audio/。
      final fileName = safePath.substring('audio/'.length);
      final target = File('${staging.path}/$fileName');
      target.parent.createSync(recursive: true);
      final bytes = entry.readBytes();
      if (bytes == null) {
        throw AudioPackDownloadException(
          AudioPackDownloadFailure.archive,
          'zip 条目无内容：$safePath',
        );
      }
      try {
        target.writeAsBytesSync(bytes);
      } catch (error) {
        throw AudioPackDownloadException(
          AudioPackDownloadFailure.archive,
          '解压失败 $safePath：$error',
        );
      }
      final expected = manifest.audioFileSha256[fileName];
      if (expected != null && Sha256Utils.fileSha256(target) != expected) {
        throw AudioPackDownloadException(
          AudioPackDownloadFailure.checksum,
          '文件 SHA-256 不匹配：$safePath',
        );
      }
    }
    if (!staging.existsSync() || staging.listSync().isEmpty) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.archive,
        'zip 内无 audio/ 文件',
      );
    }
  }

  /// 原子替换：旧 `audio/` 先改名让位，staging 改名成 `audio/`，成功后再
  /// 删除旧目录；改名失败回滚旧目录（§9.2 第 6 条"保留旧包"语义）。
  void _installStaging(Directory packDir, Directory staging, String version) {
    final audioDir = Directory('${packDir.path}/audio');
    Directory? oldDir;
    if (audioDir.existsSync()) {
      oldDir = Directory(
        '${packDir.path}/audio.old-${DateTime.now().millisecondsSinceEpoch}',
      );
      audioDir.renameSync(oldDir.path);
    }
    try {
      staging.renameSync(audioDir.path);
    } catch (error) {
      if (oldDir != null && oldDir.existsSync() && !audioDir.existsSync()) {
        oldDir.renameSync(audioDir.path);
      }
      rethrow;
    }
    if (oldDir != null && oldDir.existsSync()) {
      try {
        oldDir.deleteSync(recursive: true);
      } catch (error) {
        // 旧包清理失败仅浪费磁盘，不影响新包可用；记录供人工处理。
        AppLogger.warning('旧音频包清理失败（$version）：$error');
      }
    }
  }

  /// zip-slip 防护（TECH_DOC §9.2 安全性）：拒绝绝对路径、`..`、非 audio/
  /// 前缀条目，防止解压逃逸包目录。
  String _safeAudioPath(String name) {
    final segments = name.split('/');
    if (name.startsWith('/') ||
        segments.isEmpty ||
        segments.any((s) => s == '..' || s.isEmpty)) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.archive,
        'zip 含非法路径：$name',
      );
    }
    if (segments.first != 'audio') {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.archive,
        'zip 含非 audio/ 条目：$name',
      );
    }
    return segments.join('/');
  }

  void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) {
      throw AudioPackDownloadException(
        AudioPackDownloadFailure.cancelled,
        '下载被取消',
      );
    }
  }

  void _cleanupDownloadsDir(Directory downloadsDir) {
    try {
      if (downloadsDir.existsSync() && downloadsDir.listSync().isEmpty) {
        downloadsDir.deleteSync();
      }
    } catch (error) {
      AppLogger.warning('downloads 目录清理失败：$error');
    }
  }

}
