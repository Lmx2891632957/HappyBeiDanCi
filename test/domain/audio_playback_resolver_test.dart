/// 发音播放源解析单测（TECH_DOC §9.1）：
/// 离线包 ready 且本地文件存在 → 本地；否则 audio_url 在线兜底；皆无 → null。
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

  test('离线包 ready 且文件存在 → 本地路径优先（在线 URL 兜底不覆盖）', () {
    final source = resolver.resolve(
      pack: ready,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: true,
      audioUrl: 'https://example.com/audio/000001.mp3',
    );
    expect(source, isNotNull);
    expect(source!.localPath, '/packs/1/audio/000001.mp3');
    expect(source.url, isNull);
  });

  test('离线包 ready 但文件缺失 → 回退在线 URL', () {
    final source = resolver.resolve(
      pack: ready,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: 'https://example.com/audio/000001.mp3',
    );
    expect(source!.url, 'https://example.com/audio/000001.mp3');
  });

  test('未 ready（downloading/not_downloaded）→ 在线 URL；无 URL 返回 null', () {
    final source = resolver.resolve(
      pack: downloading,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: 'https://example.com/audio/000001.mp3',
    );
    expect(source!.url, 'https://example.com/audio/000001.mp3');

    final none = resolver.resolve(
      pack: downloading,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: null,
    );
    expect(none, isNull);
  });

  test('空 URL 与空串 URL 均视为无在线源', () {
    final none = resolver.resolve(
      pack: null,
      localPath: '/packs/1/audio/000001.mp3',
      localFileExists: false,
      audioUrl: '',
    );
    expect(none, isNull);
  });
}
