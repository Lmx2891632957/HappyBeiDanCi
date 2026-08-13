/// 离线音频包状态仓储集成测试（TECH_DOC §8.1 audio_packs / §9.3 状态机）：
/// 三态迁移（not_downloaded → downloading → ready）、进度写入、删除/回退。
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/local/app_database.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_audio_pack_repository.dart';
import 'package:happy_bei_dan_ci/domain/models/audio_pack.dart';
import 'package:happy_bei_dan_ci/domain/services/audio_pack_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'happy_beidanci_audio_pack_repo',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  (AppDatabase, AudioPackRepository) openRepo(String name) {
    final db = AppDatabase.forTesting(
      NativeDatabase(File('${tempDir.path}/$name.db')),
    );
    addTearDown(db.close);
    return (db, DriftAudioPackRepository(db));
  }

  test('空表 get 返回 null（等价 not_downloaded）', () async {
    final (_, repo) = openRepo('empty');
    expect(await repo.get(1), isNull);
  });

  test('状态迁移：markDownloading → updateProgress → markReady', () async {
    final (_, repo) = openRepo('state_machine');
    await repo.markDownloading(1, version: '1.0', totalSize: 1000, fileCount: 2);
    var pack = await repo.get(1);
    expect(pack, isNotNull);
    expect(pack!.status, AudioPackStatus.downloading);
    expect(pack.version, '1.0');
    expect(pack.totalSize, 1000);
    expect(pack.fileCount, 2);

    await repo.updateProgress(1, 400);
    pack = await repo.get(1);
    expect(pack!.downloadedSize, 400);
    expect(pack.status, AudioPackStatus.downloading);

    await repo.markReady(
      1,
      version: '1.0',
      totalSize: 1000,
      fileCount: 2,
      downloadedBytes: 500,
    );
    pack = await repo.get(1);
    expect(pack!.status, AudioPackStatus.ready);
    expect(pack.downloadedSize, 500);
    expect(pack.version, '1.0');
  });

  test('不同词书互不干扰', () async {
    final (_, repo) = openRepo('multi_book');
    await repo.markDownloading(1, version: '1.0');
    await repo.markDownloading(2, version: '1.0');
    await repo.markReady(1, version: '1.0', totalSize: 1, fileCount: 1, downloadedBytes: 1);

    expect((await repo.get(1))!.status, AudioPackStatus.ready);
    expect((await repo.get(2))!.status, AudioPackStatus.downloading);
  });

  test('reset/delete：行删除后回到无记录（not_downloaded）', () async {
    final (_, repo) = openRepo('reset');
    await repo.markDownloading(1, version: '1.0');
    await repo.reset(1);
    expect(await repo.get(1), isNull);

    await repo.markReady(1, version: '1.0', totalSize: 1, fileCount: 1, downloadedBytes: 1);
    await repo.delete(1);
    expect(await repo.get(1), isNull);
  });

  test('损坏状态值：get 抛 StateError（不静默）', () async {
    final (db, repo) = openRepo('corrupt');
    await db
        .into(db.audioPacks)
        .insert(AudioPacksCompanion.insert(
          wordbookId: Value(9),
          version: '1.0',
          status: 'bogus',
        ));
    await expectLater(repo.get(9), throwsStateError);
  });
}
