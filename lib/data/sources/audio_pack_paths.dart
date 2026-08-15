import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 离线音频包文件布局（TECH_DOC §9.2）：
/// `<应用私有目录>/audio_packs/<wordbookId>/audio/<audioKey>.mp3`。
///
/// 下载器、WorkManager 后台任务与播放服务统一引用本类，避免路径散落；
/// 目录整体随包版本原子替换（§9.2 第 6 条）。
abstract final class AudioPackPaths {
  AudioPackPaths._();

  /// 词书包根目录（不存在时创建）。
  static Future<Directory> packRoot(int wordbookId) async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/audio_packs/$wordbookId')
      ..createSync(recursive: true);
  }

  /// 包内单词音频文件路径（ready 状态下存在）。
  static String audioFilePath(Directory packRoot, String audioKey) =>
      '${packRoot.path}/audio/$audioKey.mp3';
}
