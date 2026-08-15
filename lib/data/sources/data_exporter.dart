import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/services/data_export_formatter.dart';
import '../../domain/services/review_log_repository.dart';
import '../../domain/services/user_word_repository.dart';

/// 数据导出结果（文件路径列表，供 UI 提示）。
class DataExportResult {
  const DataExportResult({required this.filePaths});

  final List<String> filePaths;
}

/// 数据导出服务（TECH_DOC §8.2）：读仓储 → 纯序列化（DataExportFormatter）→
/// 写 `<应用私有目录>/exports/` → share_plus 系统分享面板。
///
/// 分享失败不删除已生成文件（用户可再取）；文件名固定（review_logs.csv /
/// user_words.csv / export.json），重复导出覆盖旧文件。
class DataExporter {
  DataExporter({
    required ReviewLogRepository reviewLogs,
    required UserWordRepository userWords,
    Future<Directory> Function()? exportDirectory,
    Future<void> Function(List<XFile> files, String subject)? share,
    // ignore: prefer_initializing_formals
  }) : _reviewLogs = reviewLogs,
       // ignore: prefer_initializing_formals
       _userWords = userWords,
       _exportDirectory = exportDirectory ?? _defaultExportDirectory,
       _share = share ?? _defaultShare;

  final ReviewLogRepository _reviewLogs;
  final UserWordRepository _userWords;
  final Future<Directory> Function() _exportDirectory;
  final Future<void> Function(List<XFile> files, String subject) _share;

  Future<DataExportResult> export({
    required ExportFormat format,
    required String shareSubject,
  }) async {
    final logs = await _reviewLogs.getLogs();
    final words = await _userWords.getAll();
    final files = DataExportFormatter.format(
      ExportPayload(reviewLogs: logs, userWords: words),
      format,
    );
    final dir = await _exportDirectory();
    dir.createSync(recursive: true);
    final paths = <String>[];
    final xFiles = <XFile>[];
    for (final entry in files.files.entries) {
      final file = File('${dir.path}/${entry.key}')
        ..writeAsStringSync(entry.value, flush: true);
      paths.add(file.path);
      xFiles.add(XFile(file.path, mimeType: _mimeType(entry.key)));
    }
    await _share(xFiles, shareSubject);
    return DataExportResult(filePaths: paths);
  }

  static Future<Directory> _defaultExportDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/exports');
  }

  static Future<void> _defaultShare(
    List<XFile> files,
    String subject,
  ) async {
    await SharePlus.instance.share(
      ShareParams(files: files, subject: subject),
    );
  }

  static String _mimeType(String fileName) => fileName.endsWith('.json')
      ? 'application/json'
      : 'text/csv';
}
