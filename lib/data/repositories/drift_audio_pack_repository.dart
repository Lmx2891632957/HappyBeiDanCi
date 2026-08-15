import 'package:drift/drift.dart';

import '../../domain/models/audio_pack.dart';
import '../../domain/services/audio_pack_repository.dart';
import '../local/app_database.dart';

/// 离线音频包状态仓储实现（Drift，TECH_DOC §8.1 audio_packs / §9.3）。
///
/// 表结构只有三态（not_downloaded / downloading / ready，TECH_DOC §8.1），
/// `not_downloaded` 不落行、以"无记录"等价表达；版本与大小信息随行记录，
/// 供下载任务校验目标版本与展示体积（§9.2）。
class DriftAudioPackRepository implements AudioPackRepository {
  DriftAudioPackRepository(this._db);

  final AppDatabase _db;

  @override
  Future<AudioPack?> get(int wordbookId) async {
    final row = await (_db.select(
      _db.audioPacks,
    )..where((t) => t.wordbookId.equals(wordbookId))).getSingleOrNull();
    return row == null ? null : _toPack(row);
  }

  @override
  Future<void> markDownloading(
    int wordbookId, {
    required String version,
    int? totalSize,
    int? fileCount,
  }) {
    return _upsert(
      AudioPacksCompanion(
        wordbookId: Value(wordbookId),
        version: Value(version),
        status: Value(AudioPackStatus.downloading.storageValue),
        totalSize: Value(totalSize),
        fileCount: Value(fileCount),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> updateProgress(int wordbookId, int downloadedSize) {
    return (_db.update(_db.audioPacks)
          ..where((t) => t.wordbookId.equals(wordbookId)))
        .write(
      AudioPacksCompanion(
        downloadedSize: Value(downloadedSize),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> markReady(
    int wordbookId, {
    required String version,
    required int totalSize,
    required int fileCount,
    required int downloadedBytes,
  }) {
    return _upsert(
      AudioPacksCompanion(
        wordbookId: Value(wordbookId),
        version: Value(version),
        status: Value(AudioPackStatus.ready.storageValue),
        totalSize: Value(totalSize),
        // downloaded_size 语义 = zip 流已下载字节（§9.2 进度口径）；
        // ready 时即 zip 全量字节。
        downloadedSize: Value(downloadedBytes),
        fileCount: Value(fileCount),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> reset(int wordbookId) {
    return (_db.delete(_db.audioPacks)
          ..where((t) => t.wordbookId.equals(wordbookId)))
        .go();
  }

  @override
  Future<void> delete(int wordbookId) => reset(wordbookId);

  Future<void> _upsert(AudioPacksCompanion row) {
    // audio_packs 以 wordbook_id 为主键：insertOnConflictUpdate 即 upsert。
    return _db.into(_db.audioPacks).insertOnConflictUpdate(row);
  }

  AudioPack _toPack(AudioPackRow row) => AudioPack(
    wordbookId: row.wordbookId,
    version: row.version,
    status: AudioPackStatus.values.firstWhere(
      (s) => s.storageValue == row.status,
      orElse: () => throw StateError(
        'audio_packs 损坏：wordbook_id=${row.wordbookId} 未知状态 '
        '"${row.status}"（与仓储"损坏不静默"口径一致）',
      ),
    ),
    totalSize: row.totalSize,
    downloadedSize: row.downloadedSize,
    fileCount: row.fileCount,
    updatedAt: row.updatedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.updatedAt!),
  );
}
