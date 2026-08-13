/// 离线音频包下载器端到端测试（TECH_DOC §9.2）：
/// 用本地 HttpServer 模拟发布基址，覆盖 manifest 解析、Range 断点续传、
/// 整包重下（服务端忽略 Range）、SHA-256 校验、原子替换与 zip-slip 防护。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/sources/audio_pack_downloader.dart';
import 'package:happy_bei_dan_ci/data/sources/audio_pack_manifest.dart';

void main() {
  late Directory tempDir;
  late HttpClient httpClient;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_pack_downloader');
    httpClient = HttpClient();
  });

  tearDown(() async {
    httpClient.close(force: true);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 构造一份单文件测试音频包：zip 内容与 manifest 一一对应。
  ({Uint8List zipBytes, Map<String, dynamic> manifest, Uint8List mp3Bytes})
  buildPack({String shaOverride = ''}) {
    final mp3 = Uint8List.fromList(List.generate(2048, (i) => i % 251));
    final archive = Archive()
      ..addFile(ArchiveFile('audio/000001.mp3', mp3.length, mp3));
    final zip = Uint8List.fromList(ZipEncoder().encode(archive));
    final manifest = {
      'name': 'wordbook-gaokao-3500',
      'version': '1.0',
      'wordbook_id': 1,
      'schema_version': 1,
      'word_count': 3677,
      'created_at': '2026-08-13T00:00:00+00:00',
      'artifacts': {
        'wordbook_db': {'file': 'wordbook.db', 'size': 1, 'sha256': 'a'},
        'audio_zip': {
          'file': 'audio-wordbook-gaokao-3500-v1.0.zip',
          'size': zip.length,
          'sha256': shaOverride.isEmpty
              ? sha256.convert(zip).toString()
              : shaOverride,
          'file_count': 1,
          'total_size': mp3.length,
        },
        'audio_files': {
          '000001.mp3': sha256.convert(mp3).toString(),
        },
      },
      'sources': const [],
    };
    return (zipBytes: zip, manifest: manifest, mp3Bytes: mp3);
  }

  /// 启动 HttpServer 并提供 manifest / zip / Range 处理；返回服务器与请求记录。
  Future<(HttpServer, List<HttpRequest>)> startServer({
    required Uint8List zip,
    required Map<String, dynamic> manifest,
    bool supportRange = true,
  }) async {
    final requests = <HttpRequest>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request);
      if (request.uri.path == '/manifest.json') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(manifest));
        await request.response.close();
        return;
      }
      final range = request.headers.value(HttpHeaders.rangeHeader);
      final rangeMatch = supportRange
          ? RegExp(r'bytes=(\d+)-').firstMatch(range ?? '')
          : null;
      if (rangeMatch != null) {
        final start = int.parse(rangeMatch.group(1)!);
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-${zip.length - 1}/${zip.length}',
        );
        request.response.add(zip.sublist(start));
      } else {
        request.response.statusCode = HttpStatus.ok;
        request.response.add(zip);
      }
      await request.response.close();
    });
    return (server, requests);
  }

  AudioPackDownloader downloader(Directory packRoot) => AudioPackDownloader(
    packRootProvider: (_) async => packRoot,
    httpClient: httpClient,
  );

  test('fetchManifest：解析合法 manifest；缺字段抛坏包异常', () async {
    final pack = buildPack();
    final (server, _) = await startServer(zip: pack.zipBytes, manifest: pack.manifest);
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');

    final manifest = await downloader(tempDir).fetchManifest(uri);
    expect(manifest.version, '1.0');
    expect(manifest.wordbookId, 1);
    expect(manifest.zipSize, pack.zipBytes.length);
    expect(manifest.audioFileSha256['000001.mp3'], isNotNull);

    final bad = Map<String, dynamic>.from(pack.manifest)..remove('artifacts');
    final (server2, _) = await startServer(zip: pack.zipBytes, manifest: bad);
    addTearDown(server2.close);
    final uri2 = Uri.parse('http://${server2.address.host}:${server2.port}/');
    await expectLater(
      downloader(tempDir).fetchManifest(uri2),
      throwsA(
        isA<AudioPackDownloadException>().having(
          (e) => e.failure,
          'failure',
          AudioPackDownloadFailure.badManifest,
        ),
      ),
    );
  });

  test('整包下载：解压、逐文件校验、原子替换并上报进度', () async {
    final pack = buildPack();
    final (server, _) = await startServer(
      zip: pack.zipBytes,
      manifest: pack.manifest,
    );
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final packRoot = Directory('${tempDir.path}/pack1');
    final progress = <(int, int)>[];

    await downloader(packRoot).downloadAndInstall(
      wordbookId: 1,
      version: '1.0',
      baseUri: uri,
      manifest: AudioPackManifest.parse(jsonEncode(pack.manifest)),
      onProgress: (down, total) async => progress.add((down, total)),
    );

    final audioFile = File('${packRoot.path}/audio/000001.mp3');
    expect(audioFile.existsSync(), isTrue);
    expect(audioFile.readAsBytesSync(), pack.mp3Bytes);
    expect(File('${packRoot.path}/downloads/1.0.part').existsSync(), isFalse);
    expect(progress.last, (pack.zipBytes.length, pack.zipBytes.length));
    // 进度单调不减。
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i].$1, greaterThanOrEqualTo(progress[i - 1].$1));
    }
  });

  test('断点续传：已有 .part 时以 Range 从已下载字节续传', () async {
    final pack = buildPack();
    final (server, requests) = await startServer(
      zip: pack.zipBytes,
      manifest: pack.manifest,
    );
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final packRoot = Directory('${tempDir.path}/pack2');
    final half = pack.zipBytes.length ~/ 2;
    final partFile = File('${packRoot.path}/downloads/1.0.part')
      ..createSync(recursive: true)
      ..writeAsBytesSync(pack.zipBytes.sublist(0, half));

    await downloader(packRoot).downloadAndInstall(
      wordbookId: 1,
      version: '1.0',
      baseUri: uri,
      manifest: AudioPackManifest.parse(jsonEncode(pack.manifest)),
      onProgress: (_, _) async {},
    );

    expect(
      File('${packRoot.path}/audio/000001.mp3').readAsBytesSync(),
      pack.mp3Bytes,
    );
    // 续传请求必须带 Range: bytes=<half>-（先于整包 200 请求）。
    final rangeHeader = requests
        .map((r) => r.headers.value(HttpHeaders.rangeHeader))
        .whereType<String>()
        .firstWhere((h) => h == 'bytes=$half-');
    expect(rangeHeader, 'bytes=$half-');
    expect(partFile.existsSync(), isFalse);
  });

  test('服务端忽略 Range（恒 200）：整包重下仍成功', () async {
    final pack = buildPack();
    final (server, requests) = await startServer(
      zip: pack.zipBytes,
      manifest: pack.manifest,
      supportRange: false,
    );
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final packRoot = Directory('${tempDir.path}/pack3');
    // 预置一段 .part，验证服务端不支持 Range 时被清空重下。
    File('${packRoot.path}/downloads/1.0.part')
      ..createSync(recursive: true)
      ..writeAsBytesSync(List.filled(128, 1));

    await downloader(packRoot).downloadAndInstall(
      wordbookId: 1,
      version: '1.0',
      baseUri: uri,
      manifest: AudioPackManifest.parse(jsonEncode(pack.manifest)),
      onProgress: (_, _) async {},
    );

    expect(
      File('${packRoot.path}/audio/000001.mp3').readAsBytesSync(),
      pack.mp3Bytes,
    );
    // 服务端不响应 Range：客户端曾携带 Range 尝试续传，收到 200 后整包重下。
    expect(
      requests.single.headers.value(HttpHeaders.rangeHeader),
      'bytes=128-',
    );
  });

  test('SHA-256 不匹配：抛校验异常并删除 .part（不落 ready 状态）', () async {
    final pack = buildPack(shaOverride: 'f' * 64);
    final (server, _) = await startServer(
      zip: pack.zipBytes,
      manifest: pack.manifest,
    );
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final packRoot = Directory('${tempDir.path}/pack4');

    await expectLater(
      downloader(packRoot).downloadAndInstall(
        wordbookId: 1,
        version: '1.0',
        baseUri: uri,
        manifest: AudioPackManifest.parse(jsonEncode(pack.manifest)),
        onProgress: (_, _) async {},
      ),
      throwsA(
        isA<AudioPackDownloadException>().having(
          (e) => e.failure,
          'failure',
          AudioPackDownloadFailure.checksum,
        ),
      ),
    );
    expect(File('${packRoot.path}/downloads/1.0.part').existsSync(), isFalse);
    expect(Directory('${packRoot.path}/audio').existsSync(), isFalse);
  });

  test('zip-slip 防护：含 ../ 或非 audio/ 前缀的条目被拒绝', () async {
    final evil = Archive()
      ..addFile(ArchiveFile('../evil.txt', 4, Uint8List.fromList([1, 2, 3, 4])));
    final evilZip = Uint8List.fromList(ZipEncoder().encode(evil));
    final pack = buildPack();
    // manifest 与恶意 zip 保持一致（否则下载阶段尺寸不符提前失败），
    // 使流程走到解压阶段触发 zip-slip 防护。
    final manifest = Map<String, dynamic>.from(pack.manifest);
    final artifacts = manifest['artifacts'] as Map<String, dynamic>;
    artifacts['audio_zip'] = {
      'file': 'audio-wordbook-gaokao-3500-v1.0.zip',
      'size': evilZip.length,
      'sha256': sha256.convert(evilZip).toString(),
      'file_count': 0,
      'total_size': 0,
    };
    artifacts['audio_files'] = <String, String>{};
    final (server, _) = await startServer(zip: evilZip, manifest: manifest);
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final packRoot = Directory('${tempDir.path}/pack5');

    await expectLater(
      downloader(packRoot).downloadAndInstall(
        wordbookId: 1,
        version: '1.0',
        baseUri: uri,
        manifest: AudioPackManifest.parse(jsonEncode(manifest)),
        onProgress: (_, _) async {},
      ),
      throwsA(
        isA<AudioPackDownloadException>().having(
          (e) => e.failure,
          'failure',
          AudioPackDownloadFailure.archive,
        ),
      ),
    );
    expect(File('${packRoot.path}/../evil.txt').existsSync(), isFalse);
  });

  test('取消标记：下载过程中抛出 cancelled', () async {
    final pack = buildPack();
    final (server, _) = await startServer(
      zip: pack.zipBytes,
      manifest: pack.manifest,
    );
    addTearDown(server.close);
    final uri = Uri.parse('http://${server.address.host}:${server.port}/');
    final packRoot = Directory('${tempDir.path}/pack6');
    var cancelled = false;

    final future = downloader(packRoot).downloadAndInstall(
      wordbookId: 1,
      version: '1.0',
      baseUri: uri,
      manifest: AudioPackManifest.parse(jsonEncode(pack.manifest)),
      isCancelled: () => cancelled,
      onProgress: (_, _) async {
        cancelled = true; // 首个进度回调后置取消。
      },
    );

    await expectLater(
      future,
      throwsA(
        isA<AudioPackDownloadException>().having(
          (e) => e.failure,
          'failure',
          AudioPackDownloadFailure.cancelled,
        ),
      ),
    );
  });
}
