import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../core/hash_utils.dart';
import '../../core/logger.dart';
import '../../domain/services/settings_repository.dart';
import 'wordbook_importer.dart';

/// 词库首装异常分类（TECH_DOC §8.2 首装流程）。
enum WordbookInstallFailure { manifest, network, checksum, import }

/// 词库首装异常。
class WordbookInstallException implements Exception {
  const WordbookInstallException(this.failure, this.message);

  final WordbookInstallFailure failure;
  final String message;

  @override
  String toString() => 'WordbookInstallException(${failure.name}): $message';
}

/// 词库首装与升级服务（TECH_DOC §8.2 首装与升级流程）：版本判定 → 内置
/// asset 导入（TD-14，预装词库）或拉取 manifest 下载发布版 DB → SHA-256
/// 校验 → [WordbookImporter] 导入（同事务，版本键由导入器写入）。
///
/// - `settings.wordbook_version` 等于当前发布版本 → 幂等跳过；未装或落后
///   （如 v1.0 → v1.1）→ 走内置 asset 导入（`assets/wordbooks/` 预装 DB，
///   无网络），asset 缺失时回退下载导入；升级复用导入器的备份与
///   word_id 重映射，失败保留旧词库不影响学习；
/// - 并发触发（启动后台 + 今日页重试）经实例级 in-flight Future 串行化，
///   避免双导入竞态；
/// - 失败不产生半装状态（下载失败删半包；导入失败事务回滚），
///   由调用方（今日页）提示重试。
class WordbookInstaller {
  WordbookInstaller({
    required this.importer,
    required this.settingsRepository,
    HttpClient? httpClient,
    Future<Directory> Function()? downloadDirectory,
    Uri Function()? releaseBaseUri,
    String? latestVersion,
    Future<Uint8List> Function(String assetPath)? assetLoader,
  }) : _http = httpClient ?? HttpClient(),
       _downloadDirectory =
           downloadDirectory ?? _defaultDownloadDirectory,
       _releaseBaseUriOverride = releaseBaseUri,
       _latestVersion = latestVersion ?? defaultLatestVersion,
       _assetLoader = assetLoader ?? _defaultAssetLoader;

  /// 当前发布词库版本（与内容管线发布号对齐；v1.1 起支持升级，发布新词库时
  /// 手动更新；多词书/自动版本探测见 M2 增强，TECH_DOC §8.2）。
  static const String defaultLatestVersion = '1.1';

  final WordbookImporter importer;
  final SettingsRepository settingsRepository;
  final HttpClient _http;
  final Future<Directory> Function() _downloadDirectory;
  final Uri Function()? _releaseBaseUriOverride;
  final String _latestVersion;

  /// 内置词库 DB asset 读取器（TD-14）：默认读 rootBundle，测试注入假 loader。
  final Future<Uint8List> Function(String assetPath) _assetLoader;

  Future<String?>? _inFlight;

  /// 确保词库已安装；返回安装的版本（已装/无发布包返回 null）。
  /// 并发调用共享同一 in-flight Future（串行化，§8.2 首装流程）。
  Future<String?> ensureInstalled() {
    final pending = _inFlight;
    if (pending != null) {
      return pending;
    }
    final run = _ensureInstalled();
    _inFlight = run;
    return run.whenComplete(() => _inFlight = null);
  }

  Future<String?> _ensureInstalled() async {
    final settings = await settingsRepository.load();
    final installed = settings.wordbookVersion;
    if (installed == _latestVersion) {
      return null; // 已是最新版本：幂等跳过。
    }
    // TD-14 内容全内置：先尝试内置 asset 导入（本地、无网络）；asset 缺失
    // （未注入/非内置词书）回退下载流程（保留，供 M2 可下载词书）。
    final assetBytes = await _tryLoadBuiltInDb();
    if (assetBytes != null) {
      try {
        return await _importFromBytes(assetBytes);
      } on WordbookInstallException {
        rethrow;
      } catch (error) {
        throw WordbookInstallException(
          WordbookInstallFailure.import,
          '内置词库导入失败：$error',
        );
      }
    }
    try {
      final baseUri = _releaseBaseUri();
      final manifest = await _fetchManifest(baseUri);
      final dbName = manifest['file'] as String;
      final expectedSha = manifest['sha256'] as String;
      final dir = await _downloadDirectory();
      dir.createSync(recursive: true);
      final target = File('${dir.path}/$dbName');
      await _downloadVerified(
        baseUri.resolve(dbName),
        target,
        expectedSha256: expectedSha,
      );
      final result = await importer.importFromFile(target);
      return result.version;
    } on WordbookInstallException {
      rethrow;
    } on FormatException catch (error) {
      throw WordbookInstallException(
        WordbookInstallFailure.manifest,
        'manifest 解析失败：$error',
      );
    } catch (error) {
      throw WordbookInstallException(
        WordbookInstallFailure.import,
        '词库安装失败：$error',
      );
    }
  }

  /// 读取内置词库 DB asset 字节；asset 不存在（未注入）返回 null 回退下载。
  Future<Uint8List?> _tryLoadBuiltInDb() async {
    final assetPath = AppConstants.builtInWordbookDbAsset(_latestVersion);
    try {
      return await _assetLoader(assetPath);
    } on FlutterError {
      return null; // asset 缺失：走下载流程。
    } catch (error) {
      // 其他读取失败（IO 等）：同样回退下载，不阻断安装（§8.2 失败语义）。
      AppLogger.warning('内置词库 asset 读取失败（$assetPath）：$error');
      return null;
    }
  }

  /// 内置 asset 导入：字节写临时文件后复用 [WordbookImporter]（校验/备份/
  /// 整体替换/word_id remap/版本键口径与下载导入完全一致，TECH_DOC §8.2）。
  Future<String> _importFromBytes(Uint8List bytes) async {
    final dir = await _downloadDirectory();
    dir.createSync(recursive: true);
    final target = File(
      '${dir.path}/${AppConstants.builtInWordbookDbFileName(_latestVersion)}',
    );
    await target.writeAsBytes(bytes, flush: true);
    final result = await importer.importFromFile(target);
    return result.version;
  }

  static Future<Uint8List> _defaultAssetLoader(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// 发布基址：测试可注入 override；默认按当前发布版本拼 GitHub Releases URL。
  Uri _releaseBaseUri() =>
      _releaseBaseUriOverride?.call() ??
      Uri.parse(
        AppConstants.audioPackReleaseBaseUrl(
          AppConstants.defaultWordbookPackBase,
          _latestVersion,
        ),
      );

  Future<Map<String, dynamic>> _fetchManifest(Uri baseUri) async {
    final request = await _http
        .getUrl(baseUri.resolve('manifest.json'))
        .timeout(const Duration(seconds: 30));
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw WordbookInstallException(
        WordbookInstallFailure.manifest,
        'manifest HTTP ${response.statusCode}',
      );
    }
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    final wordbookDb = (json as Map<String, dynamic>)['artifacts']
        ?['wordbook_db'];
    if (wordbookDb is! Map<String, dynamic> ||
        wordbookDb['file'] is! String ||
        wordbookDb['sha256'] is! String) {
      throw const WordbookInstallException(
        WordbookInstallFailure.manifest,
        'manifest 缺少 artifacts.wordbook_db',
      );
    }
    return wordbookDb.cast<String, dynamic>();
  }

  /// 下载并流式校验 SHA-256；校验失败删除半包（不残留脏文件）。
  Future<void> _downloadVerified(
    Uri uri,
    File target, {
    required String expectedSha256,
  }) async {
    if (target.existsSync()) {
      target.deleteSync();
    }
    final request = await _http.getUrl(uri).timeout(const Duration(seconds: 30));
    final response = await request.close().timeout(const Duration(seconds: 60));
    if (response.statusCode != HttpStatus.ok) {
      throw WordbookInstallException(
        WordbookInstallFailure.network,
        '词库 DB HTTP ${response.statusCode}',
      );
    }
    final sink = target.openSync(mode: FileMode.write);
    try {
      await for (final chunk in response) {
        sink.writeFromSync(chunk);
      }
      sink.closeSync();
    } catch (error) {
      try {
        sink.closeSync();
      } catch (_) {
        // 关闭失败忽略：文件随后删除。
      }
      target.deleteSync();
      throw WordbookInstallException(
        WordbookInstallFailure.network,
        '下载中断：$error',
      );
    }
    final actual = Sha256Utils.fileSha256(target);
    if (actual != expectedSha256) {
      target.deleteSync();
      throw WordbookInstallException(
        WordbookInstallFailure.checksum,
        '词库 DB SHA-256 不匹配',
      );
    }
  }

  static Future<Directory> _defaultDownloadDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/wordbooks');
  }
}
