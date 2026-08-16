/// 发音播放源解析单测（TECH_DOC §9.1）：
/// 内置词书 → AssetSource（TD-14）；否则离线包 ready 且本地文件存在 → 本地；
/// 否则 audio_url 在线兜底；皆无 → null。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/sources/audio_playback_service.dart';
import 'package:happy_bei_dan_ci/domain/models/audio_pack.dart';

void main() {
  const resolver = AudioPlaybackSourceResolver();
  const ready = AudioPack(
    wordbookId: 1,
    version: '1.0',
    status: AudioPackStatus.ready,
  );
  const downloading = AudioPack(
    wordbookId: 1,
    version: '1.0',
    status: AudioPackStatus.downloading,
  );
  const builtInAsset = 'assets/audio/000001.mp3';

  test('离线包 ready 且文件存在 → 本地路径优先（在线 URL 兜底不覆盖）', () {
    final source = resolver.resolve(
      pack: ready,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: true,
      audioUrl: 'https://example.com/audio/000001.mp3',
      isBuiltIn: false,
      assetPath: builtInAsset,
    );
    expect(source, isNotNull);
    expect(source!.localPath, '/packs/1/audio/000001.mp3');
    expect(source.url, isNull);
    expect(source.assetPath, isNull);
  });

  test('离线包 ready 但文件缺失 → 回退在线 URL', () {
    final source = resolver.resolve(
      pack: ready,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: 'https://example.com/audio/000001.mp3',
      isBuiltIn: false,
      assetPath: builtInAsset,
    );
    expect(source!.url, 'https://example.com/audio/000001.mp3');
  });

  test('未 ready（downloading/not_downloaded）→ 在线 URL；无 URL 返回 null', () {
    final source = resolver.resolve(
      pack: downloading,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: 'https://example.com/audio/000001.mp3',
      isBuiltIn: false,
      assetPath: builtInAsset,
    );
    expect(source!.url, 'https://example.com/audio/000001.mp3');

    final none = resolver.resolve(
      pack: downloading,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: null,
      isBuiltIn: false,
      assetPath: builtInAsset,
    );
    expect(none, isNull);
  });

  test('空 URL 与空串 URL 均视为无在线源', () {
    final none = resolver.resolve(
      pack: null,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: '',
      isBuiltIn: false,
      assetPath: builtInAsset,
    );
    expect(none, isNull);
  });

  test('内置词书（isBuiltIn）→ AssetSource 直读 asset，优先于本地包/在线 URL', () {
    final source = resolver.resolve(
      pack: ready,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: true,
      audioUrl: 'https://example.com/audio/000001.mp3',
      isBuiltIn: true,
      assetPath: builtInAsset,
    );
    expect(source, isNotNull);
    expect(source!.assetPath, builtInAsset);
    expect(source.localPath, isNull);
    expect(source.url, isNull);
  });

  test('内置词书即使本地包缺失/无在线 URL 也返回 AssetSource（asset 随 APK 打包）', () {
    final source = resolver.resolve(
      pack: null,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: null,
      isBuiltIn: true,
      assetPath: builtInAsset,
    );
    expect(source!.assetPath, builtInAsset);
  });
}
