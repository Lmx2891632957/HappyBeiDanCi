import '../models/audio_pack.dart';

/// 离线音频包下载状态仓储契约（TECH_DOC §8.1 audio_packs / §9.3 状态机）。
///
/// 状态迁移：`not_downloaded → downloading → ready`；下载失败/中断保持在
/// `downloading`（保留 downloaded_size 供断点续传），不可恢复错误（如
/// SHA-256 校验失败）回退 `not_downloaded`。表结构只有三态，无独立 failed
/// 状态（§9.3 口径），失败信息不落库、由 WorkManager 退避重试承载。
abstract interface class AudioPackRepository {
  /// 读取词书下载状态；无记录返回 null（等价 not_downloaded）。
  Future<AudioPack?> get(int wordbookId);

  /// 开始/恢复下载：置 `downloading` 并记录目标版本与包信息。
  Future<void> markDownloading(
    int wordbookId, {
    required String version,
    int? totalSize,
    int? fileCount,
  });

  /// 进度更新（TECH_DOC §9.2：分块写入 downloaded_size）。
  Future<void> updateProgress(int wordbookId, int downloadedSize);

  /// 校验通过并原子替换完成后置 `ready`。
  Future<void> markReady(
    int wordbookId, {
    required String version,
    required int totalSize,
    required int fileCount,
    required int downloadedBytes,
  });

  /// 回退到 `not_downloaded`（SHA-256 校验失败等不可恢复错误，清空进度）。
  Future<void> reset(int wordbookId);

  /// 删除状态行（用户删除/版本失效；包目录清理由调用方负责，§9.2 第 8 条）。
  Future<void> delete(int wordbookId);
}
