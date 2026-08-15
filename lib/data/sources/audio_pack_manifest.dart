import 'dart:convert';

/// 离线音频包 manifest（TECH_DOC §9.2，由内容管线打包脚本生成）。
///
/// App 端只消费 `artifacts.audio_zip`（zip 整体 SHA-256、压缩/解压体积）与
/// `artifacts.audio_files`（逐文件 SHA-256，解压后复核）；字段缺失视为坏包，
/// 拒绝下载（与词库导入"包校验失败拒绝导入"口径一致，§8.2）。
class AudioPackManifest {
  const AudioPackManifest({
    required this.name,
    required this.version,
    required this.wordbookId,
    required this.wordCount,
    required this.zipFileName,
    required this.zipSize,
    required this.zipSha256,
    required this.totalSize,
    required this.fileCount,
    required this.audioFileSha256,
  });

  final String name;
  final String version;
  final int wordbookId;
  final int wordCount;

  /// 音频 zip 文件名（`artifacts.audio_zip.file`）。
  final String zipFileName;

  /// 压缩后 zip 体积（断点续传的目标大小与进度分母）。
  final int zipSize;
  final String zipSha256;

  /// 解压后音频总字节（离线包体积预估展示口径，PRD F5 约 50–100 MB）。
  final int totalSize;
  final int fileCount;

  /// 逐文件 SHA-256：文件名（如 `000001.mp3`）→ 十六进制摘要。
  final Map<String, String> audioFileSha256;

  /// 从 manifest.json 文本解析；缺字段抛 [FormatException]（坏包拒绝）。
  factory AudioPackManifest.parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('manifest 顶层必须是 JSON 对象');
    }
    final audioZip = json['artifacts']?['audio_zip'];
    final audioFiles = json['artifacts']?['audio_files'];
    if (audioZip is! Map<String, dynamic> ||
        audioFiles is! Map<String, dynamic>) {
      throw const FormatException('manifest 缺少 artifacts.audio_zip / audio_files');
    }
    String requiredString(Map<String, dynamic> map, String key) {
      final value = map[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('manifest 字段缺失或非法：$key');
      }
      return value;
    }

    int requiredInt(Map<String, dynamic> map, String key) {
      final value = map[key];
      if (value is! int) {
        throw FormatException('manifest 字段缺失或非法：$key');
      }
      return value;
    }

    final shaMap = <String, String>{
      for (final entry in audioFiles.entries)
        if (entry.value is String) entry.key: entry.value as String,
    };
    return AudioPackManifest(
      name: requiredString(json, 'name'),
      version: requiredString(json, 'version'),
      wordbookId: requiredInt(json, 'wordbook_id'),
      wordCount: requiredInt(json, 'word_count'),
      zipFileName: requiredString(audioZip, 'file'),
      zipSize: requiredInt(audioZip, 'size'),
      zipSha256: requiredString(audioZip, 'sha256'),
      totalSize: requiredInt(audioZip, 'total_size'),
      fileCount: requiredInt(audioZip, 'file_count'),
      audioFileSha256: shaMap,
    );
  }

  /// 下载基址下的 zip 完整 URL。
  Uri zipUri(Uri baseUri) => baseUri.resolve(zipFileName);
}
