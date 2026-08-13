import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../core/logger.dart';
import '../../domain/models/audio_pack.dart';
import '../../domain/services/audio_pack_repository.dart';
import '../../domain/services/settings_repository.dart';
import 'audio_pack_paths.dart';

/// 播放源（本地文件或在线 URL 二选一）。
class AudioPlaybackSource {
  const AudioPlaybackSource({this.localPath, this.url});

  final String? localPath;
  final String? url;
}

/// 播放源解析器（TECH_DOC §9.1）：纯逻辑，便于单测。
///
/// 顺序：发音开关在服务层判断 → 离线包 `ready` 且本地文件存在 → 本地；
/// 否则 `audio_url` 在线兜底；两者皆无返回 null（静默忽略，不打断学习）。
class AudioPlaybackSourceResolver {
  const AudioPlaybackSourceResolver();

  AudioPlaybackSource? resolve({
    required AudioPack? pack,
    required String localPath,
    required bool localFileExists,
    required String? audioUrl,
  }) {
    if (pack?.status == AudioPackStatus.ready && localFileExists) {
      return AudioPlaybackSource(localPath: localPath);
    }
    if (audioUrl != null && audioUrl.isNotEmpty) {
      return AudioPlaybackSource(url: audioUrl);
    }
    return null;
  }
}

/// 发音播放服务（PRD F5 / TECH_DOC §9.1）：封装 just_audio，单例复用
/// `AudioPlayer`，按"离线包 ready → 本地文件 / audio_url 在线"即时解析。
///
/// 播放失败（网络、文件缺失）静默记录日志，不向 UI 抛错——发音是增强体验，
/// 不得阻塞卡片翻面与评分节奏（T-02）。
class AudioPlaybackService {
  AudioPlaybackService({
    required SettingsRepository settingsRepository,
    required AudioPackRepository audioPackRepository,
    AudioPlayer? player,
    AudioPlaybackSourceResolver? resolver,
  }) : _settings = settingsRepository,
       _packs = audioPackRepository,
       _player = player ?? AudioPlayer(),
       _resolver = resolver ?? const AudioPlaybackSourceResolver();

  final SettingsRepository _settings;
  final AudioPackRepository _packs;
  final AudioPlayer _player;
  final AudioPlaybackSourceResolver _resolver;

  /// 播放单词发音；发音开关关闭或无可用播放源时为 no-op。
  Future<void> play({
    required int wordbookId,
    required String audioKey,
    String? audioUrl,
  }) async {
    final settings = await _settings.load();
    if (!settings.pronunciationEnabled) {
      return;
    }
    final pack = await _packs.get(wordbookId);
    final packRoot = await AudioPackPaths.packRoot(wordbookId);
    final localPath = AudioPackPaths.audioFilePath(packRoot, audioKey);
    final source = _resolver.resolve(
      pack: pack,
      localPath: localPath,
      localFileExists: File(localPath).existsSync(),
      audioUrl: audioUrl,
    );
    if (source == null) {
      return;
    }
    try {
      if (source.localPath != null) {
        await _player.setFilePath(source.localPath!);
      } else {
        await _player.setUrl(source.url!);
      }
      // 播放不阻塞 UI：失败在 just_audio 内部回调，此处仅防同步异常。
      unawaited(_player.play());
    } catch (error) {
      AppLogger.warning(
        '发音播放失败（wordbook=$wordbookId key=$audioKey）：$error',
      );
    }
  }

  /// 停止当前播放（翻卡/退出会话时调用，避免串音）。
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (error) {
      AppLogger.warning('停止播放失败：$error');
    }
  }

  Future<void> dispose() => _player.dispose();
}
