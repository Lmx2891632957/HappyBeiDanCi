import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';

import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../domain/models/audio_pack.dart';
import '../../domain/services/audio_pack_repository.dart';
import '../../domain/services/settings_repository.dart';
import '../../domain/services/wordbook_repository.dart';
import 'audio_pack_paths.dart';

/// 播放源（内置 asset / 本地文件 / 在线 URL 三选一，TD-14）。
class AudioPlaybackSource {
  const AudioPlaybackSource({this.assetPath, this.localPath, this.url});

  /// 内置词书发音 asset 路径（`assets/audio/<key>.mp3`，随 APK 打包）。
  final String? assetPath;
  final String? localPath;
  final String? url;
}

/// 播放源解析器（TECH_DOC §9.1）：纯逻辑，便于单测。
///
/// 顺序：发音开关在服务层判断 → 内置词书（level=gaokao，TD-14）→
/// `AssetSource` 直读内置 asset；否则离线包 `ready` 且本地文件存在 → 本地；
/// 再否则 `audio_url` 在线兜底；两者皆无返回 null（静默忽略，不打断学习）。
/// 本地文件/在线分支保留，供 M2 可下载词书复用。
class AudioPlaybackSourceResolver {
  const AudioPlaybackSourceResolver();

  AudioPlaybackSource? resolve({
    required AudioPack? pack,
    required String localPath,
    required bool localFileExists,
    required String? audioUrl,
    required bool isBuiltIn,
    required String assetPath,
  }) {
    if (isBuiltIn) {
      // 内置词书：发音随 APK 打包，直读 asset（零拷贝、零额外存储）；
      // asset 与 APK 同生命周期，无需存在性检查。
      return AudioPlaybackSource(assetPath: assetPath);
    }
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
/// `AudioPlayer`，按"内置词书 → AssetSource / 离线包 ready → 本地文件 /
/// audio_url 在线"即时解析。
///
/// 播放失败（网络、文件缺失）静默记录日志，不向 UI 抛错——发音是增强体验，
/// 不得阻塞卡片翻面与评分节奏（T-02）。
class AudioPlaybackService {
  AudioPlaybackService({
    required SettingsRepository settingsRepository,
    required AudioPackRepository audioPackRepository,
    WordbookRepository? wordbookRepository,
    AudioPlayer? player,
    AudioPlaybackSourceResolver? resolver,
  }) : _settings = settingsRepository,
       _packs = audioPackRepository,
       _wordbooks = wordbookRepository,
       _player = player ?? AudioPlayer(),
       _resolver = resolver ?? const AudioPlaybackSourceResolver();

  final SettingsRepository _settings;
  final AudioPackRepository _packs;

  /// 词书仓储（查内置判定）；测试可传 null（非内置，走原分支）。
  final WordbookRepository? _wordbooks;
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
    // TD-14：内置词书（level=gaokao）发音直读 asset；单行索引查询，开销可忽略。
    final repo = _wordbooks;
    final book = repo == null ? null : await repo.getWordbookById(wordbookId);
    final isBuiltIn = AppConstants.isBuiltInWordbookLevel(book?.level);
    final pack = await _packs.get(wordbookId);
    final packRoot = await AudioPackPaths.packRoot(wordbookId);
    final localPath = AudioPackPaths.audioFilePath(packRoot, audioKey);
    final source = _resolver.resolve(
      pack: pack,
      localPath: localPath,
      localFileExists: File(localPath).existsSync(),
      audioUrl: audioUrl,
      isBuiltIn: isBuiltIn,
      assetPath: AppConstants.builtInAudioAsset(audioKey),
    );
    if (source == null) {
      return;
    }
    try {
      if (source.assetPath != null) {
        await _player.setAsset(source.assetPath!);
      } else if (source.localPath != null) {
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
