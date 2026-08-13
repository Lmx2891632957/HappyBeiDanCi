import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../core/hash_utils.dart';
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

/// 词库首装服务（TECH_DOC §8.2 首装流程）：拉取 manifest → 下载发布版 DB →
/// SHA-256 校验 → [WordbookImporter] 导入（同事务，版本键由导入器写入）。
///
/// - `settings.wordbook_version` 非空即视为已装，幂等跳过；
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
  }) : _http = httpClient ?? HttpClient(),
       _downloadDirectory =
           downloadDirectory ?? _defaultDownloadDirectory,
       _releaseBaseUri = releaseBaseUri ?? _defaultReleaseBaseUri;

  final WordbookImporter importer;
  final SettingsRepository settingsRepository;
  final HttpClient _http;
  final Future<Directory> Function() _downloadDirectory;
  final Uri Function() _releaseBaseUri;

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
    if (installed != null && installed.isNotEmpty) {
      return null; // 已装：幂等跳过。
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

  /// M1 单词书固定取当前发布版本号（与内容管线 `VERSION` 解耦：客户端按
  /// `wordbook-gaokao-3500-v1.0` 拉取；多词书/版本探测见 M2 增强）。
  static String _latestVersion() => '1.0';

  static Uri _defaultReleaseBaseUri() => Uri.parse(
    AppConstants.audioPackReleaseBaseUrl(
      AppConstants.defaultWordbookPackBase,
      _latestVersion(),
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
