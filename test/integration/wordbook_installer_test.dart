/// 词库首装服务集成测试（TECH_DOC §8.2 首装流程）：
/// manifest 拉取 → DB 下载 → SHA-256 校验 → 导入落版本键；幂等、校验失败
/// 清理半包、坏 manifest 拒绝；内置 asset 导入分支（TD-14）与下载回退。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/core/constants.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_settings_repository.dart';
import 'package:happy_bei_dan_ci/data/sources/wordbook_installer.dart';
import 'package:happy_bei_dan_ci/data/sources/wordbook_importer.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../helpers/fixture.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late Directory downloadDir;
  late Directory backupDir;
  late HttpClient httpClient;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('happy_beidanci_installer');
    db = openTestDb(tempDir, 'install');
    downloadDir = Directory('${tempDir.path}/wordbooks');
    backupDir = Directory('${tempDir.path}/backups');
    httpClient = HttpClient();
  });

  tearDown(() async {
    httpClient.close(force: true);
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 构造单词发布版 DB（meta + 1 词，与管线打包 schema 一致）。
  File writePackFile({String version = '1.0', String word = 'apple'}) {
    final file = File('${tempDir.path}/pack_$version.db');
    final pack = sqlite.sqlite3.open(file.path);
    try {
      pack.execute('''
        CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE wordbooks (
          id INTEGER PRIMARY KEY, name TEXT NOT NULL, level TEXT NOT NULL,
          total_count INTEGER NOT NULL, source TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL
        );
        CREATE TABLE words (
          id INTEGER PRIMARY KEY, word TEXT NOT NULL UNIQUE, phonetic TEXT NOT NULL,
          phonetic_uk TEXT, meanings TEXT NOT NULL, examples TEXT NOT NULL,
          frequency TEXT NOT NULL, root_affix TEXT, audio_key TEXT NOT NULL,
          audio_url TEXT, created_at INTEGER NOT NULL
        );
        CREATE TABLE wordbook_items (
          wordbook_id INTEGER NOT NULL, word_id INTEGER NOT NULL,
          seq INTEGER NOT NULL, shuffled INTEGER NOT NULL,
          is_skipped INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (wordbook_id, word_id)
        );
      ''');
      pack.execute(
        "INSERT INTO meta (key, value) VALUES ('schema_version', '1')",
      );
      pack.execute(
        'INSERT INTO meta (key, value) VALUES (?, ?)',
        ['wordlist_version', version],
      );
      pack.execute(
        'INSERT INTO wordbooks (id, name, level, total_count, source, '
        'created_at) VALUES (1, ?, ?, 1, ?, 1)',
        ['测试词书', 'gaokao', 'test-pack'],
      );
      pack.execute(
        'INSERT INTO words (id, word, phonetic, meanings, examples, '
        'frequency, audio_key, created_at) VALUES (1, ?, ?, ?, ?, ?, ?, 1)',
        [
          word,
          '/$word/',
          jsonEncode([
            {'pos': 'n.', 'meaning': '释义$word'},
          ]),
          jsonEncode([
            {'en': 'I read $word.', 'source': 'Tatoeba', 'attribution': 't'},
          ]),
          'high',
          '000001',
        ],
      );
      pack.execute(
        'INSERT INTO wordbook_items (wordbook_id, word_id, seq, shuffled) '
        'VALUES (1, 1, 0, 0)',
      );
    } finally {
      pack.close();
    }
    return file;
  }

  /// 启动发布基址 HttpServer：manifest + 词库 DB。
  Future<(HttpServer, Map<String, String>)> startServer({
    required File pack,
    Map<String, dynamic>? manifestOverride,
  }) async {
    final bytes = pack.readAsBytesSync();
    final dbName = pack.uri.pathSegments.last;
    final manifest = manifestOverride ??
        {
          'name': 'wordbook-gaokao-3500',
          'version': '1.0',
          'wordbook_id': 1,
          'artifacts': {
            'wordbook_db': {
              'file': dbName,
              'size': bytes.length,
              'sha256': sha256.convert(bytes).toString(),
            },
          },
        };
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/manifest.json') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(manifest));
      } else {
        request.response.add(bytes);
      }
      await request.response.close();
    });
    return (
      server,
      {'dbName': dbName},
    );
  }

  WordbookInstaller installer(
    HttpServer server, {
    String latestVersion = '1.0',
    Future<Uint8List> Function(String assetPath)? assetLoader,
  }) => WordbookInstaller(
    importer: WordbookImporter(
      db,
      backupWriter: _TempBackupWriter(backupDir),
    ),
    settingsRepository: DriftSettingsRepository(db),
    httpClient: httpClient,
    downloadDirectory: () async => downloadDir,
    releaseBaseUri: () => Uri.parse(
      'http://${server.address.host}:${server.port}/',
    ),
    latestVersion: latestVersion,
    assetLoader: assetLoader,
  );

  /// 仅用内置 asset 导入的安装器：发布基址指向不可达地址，若回退下载被执行
  /// 必然失败（证明 asset 分支优先、无网络依赖，TD-14）。
  WordbookInstaller assetInstaller(
    Future<Uint8List> Function(String assetPath) assetLoader, {
    String latestVersion = '1.0',
  }) => WordbookInstaller(
    importer: WordbookImporter(
      db,
      backupWriter: _TempBackupWriter(backupDir),
    ),
    settingsRepository: DriftSettingsRepository(db),
    httpClient: httpClient,
    downloadDirectory: () async => downloadDir,
    releaseBaseUri: () => Uri.parse('http://127.0.0.1:1/'),
    latestVersion: latestVersion,
    assetLoader: assetLoader,
  );

  test('首装：manifest → 下载校验 → 导入 → 版本键落库；再次调用幂等', () async {
    final pack = writePackFile();
    final (server, _) = await startServer(pack: pack);
    addTearDown(server.close);
    final inst = installer(server);

    final version = await inst.ensureInstalled();
    expect(version, '1.0');
    final settings = await DriftSettingsRepository(db).load();
    expect(settings.wordbookVersion, '1.0');
    expect(await db.select(db.wordbooks).get(), hasLength(1));
    expect(await db.select(db.words).get(), hasLength(1));

    // 已装：幂等 no-op（不重新下载/导入）。
    expect(await inst.ensureInstalled(), isNull);
  });

  test('SHA-256 不匹配：抛校验异常并删除半包，不落版本键', () async {
    final pack = writePackFile();
    final (server, _) = await startServer(
      pack: pack,
      manifestOverride: {
        'name': 'wordbook-gaokao-3500',
        'version': '1.0',
        'wordbook_id': 1,
        'artifacts': {
          'wordbook_db': {
            'file': pack.uri.pathSegments.last,
            'size': 1,
            'sha256': 'f' * 64,
          },
        },
      },
    );
    addTearDown(server.close);

    await expectLater(
      installer(server).ensureInstalled(),
      throwsA(
        isA<WordbookInstallException>().having(
          (e) => e.failure,
          'failure',
          WordbookInstallFailure.checksum,
        ),
      ),
    );
    expect(downloadDir.listSync(), isEmpty);
    expect((await DriftSettingsRepository(db).load()).wordbookVersion, isNull);
  });

  test('坏 manifest（缺 wordbook_db）：拒绝安装', () async {
    final pack = writePackFile();
    final (server, _) = await startServer(
      pack: pack,
      manifestOverride: {'name': 'bad', 'version': '1.0', 'wordbook_id': 1},
    );
    addTearDown(server.close);

    await expectLater(
      installer(server).ensureInstalled(),
      throwsA(
        isA<WordbookInstallException>().having(
          (e) => e.failure,
          'failure',
          WordbookInstallFailure.manifest,
        ),
      ),
    );
  });

  test('升级：已装 v1.0 落后时自动下载导入 v1.1 并更新版本键', () async {
    // 先装 v1.0（word=apple）。
    final packV1 = writePackFile(version: '1.0', word: 'apple');
    final (serverV1, _) = await startServer(pack: packV1);
    addTearDown(serverV1.close);
    final instV1 = installer(serverV1);
    expect(await instV1.ensureInstalled(), '1.0');
    expect(
      (await DriftSettingsRepository(db).load()).wordbookVersion,
      '1.0',
    );

    // 发布 v1.1（word=banana）：同一 App 以最新版本常量重新判定并升级。
    final packV11 = writePackFile(version: '1.1', word: 'banana');
    final (serverV11, _) = await startServer(pack: packV11);
    addTearDown(serverV11.close);
    final instV11 = installer(serverV11, latestVersion: '1.1');
    final version = await instV11.ensureInstalled();
    expect(version, '1.1');
    expect(
      (await DriftSettingsRepository(db).load()).wordbookVersion,
      '1.1',
    );
    final words = await db.select(db.words).get();
    expect(words.single.word, 'banana');
    // 升级备份已写入（导入器口径，§8.2）。
    expect(backupDir.listSync(), isNotEmpty);

    // 已是最新：幂等 no-op。
    expect(await instV11.ensureInstalled(), isNull);
  });

  test('内置 asset 导入：字节输入写临时文件 → 导入落版本键；再次调用幂等（无网络）', () async {
    final pack = writePackFile();
    final inst = assetInstaller((assetPath) async {
      expect(assetPath, AppConstants.builtInWordbookDbAsset('1.0'));
      return pack.readAsBytes();
    });

    final version = await inst.ensureInstalled();
    expect(version, '1.0');
    final settings = await DriftSettingsRepository(db).load();
    expect(settings.wordbookVersion, '1.0');
    expect(await db.select(db.wordbooks).get(), hasLength(1));
    expect(await db.select(db.words).get(), hasLength(1));
    // 临时文件复用下载目录（命名与发布产物一致，§8.2 asset 分支）。
    expect(downloadDir.listSync(), hasLength(1));
    expect(
      downloadDir
          .listSync()
          .single
          .path
          .endsWith(AppConstants.builtInWordbookDbFileName('1.0')),
      isTrue,
    );

    // 已装：幂等 no-op（不重新读 asset/导入）。
    expect(await inst.ensureInstalled(), isNull);
  });

  test('内置 asset 缺失（未注入）→ 回退下载导入流程', () async {
    final pack = writePackFile();
    final (server, _) = await startServer(pack: pack);
    addTearDown(server.close);
    final inst = installer(
      server,
      assetLoader: (assetPath) async {
        expect(assetPath, AppConstants.builtInWordbookDbAsset('1.0'));
        throw FlutterError('asset 不存在：未注入');
      },
    );

    expect(await inst.ensureInstalled(), '1.0');
    expect(
      (await DriftSettingsRepository(db).load()).wordbookVersion,
      '1.0',
    );
    expect(await db.select(db.words).get(), hasLength(1));
  });

  test('内置 asset 内容损坏（非 sqlite）→ 抛导入异常、无半装、版本键未写', () async {
    final inst = assetInstaller(
      (assetPath) async => Uint8List.fromList([1, 2, 3]),
    );

    await expectLater(
      inst.ensureInstalled(),
      throwsA(
        isA<WordbookInstallException>().having(
          (e) => e.failure,
          'failure',
          WordbookInstallFailure.import,
        ),
      ),
    );
    expect((await DriftSettingsRepository(db).load()).wordbookVersion, isNull);
    expect(await db.select(db.wordbooks).get(), isEmpty);
    expect(await db.select(db.words).get(), isEmpty);
  });
}

/// 测试用备份写入器：写临时目录（生产实现写应用私有目录，TECH_DOC §8.2）。
class _TempBackupWriter implements BackupWriter {
  _TempBackupWriter(this.dir);

  final Directory dir;

  @override
  Future<File> write({required String name, required String content}) async {
    await dir.create(recursive: true);
    return File('${dir.path}/$name').writeAsString(content);
  }
}
