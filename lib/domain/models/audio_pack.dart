/// 离线音频包下载状态模型（TECH_DOC §8.1 audio_packs 表）。
class AudioPack {
  const AudioPack({
    required this.wordbookId,
    required this.version,
    required this.status,
    this.totalSize,
    this.downloadedSize,
    this.fileCount,
    this.updatedAt,
  });

  final int wordbookId;
  final String version;
  final AudioPackStatus status;
  final int? totalSize;
  final int? downloadedSize;
  final int? fileCount;
  final DateTime? updatedAt;
}

/// 离线包下载状态（TECH_DOC §9.2）。
enum AudioPackStatus {
  notDownloaded,
  downloading,
  ready;

  String get storageValue => switch (this) {
    AudioPackStatus.notDownloaded => 'not_downloaded',
    AudioPackStatus.downloading => 'downloading',
    AudioPackStatus.ready => 'ready',
  };
}
