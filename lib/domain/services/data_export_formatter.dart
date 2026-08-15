import 'dart:convert';

import '../models/review_log.dart';
import '../models/user_word.dart';

/// 数据导出格式（TECH_DOC §8.2；设置页触发）。
enum ExportFormat { csv, json }

/// 导出内容（序列化前的纯数据，来自仓储查询）。
class ExportPayload {
  const ExportPayload({required this.reviewLogs, required this.userWords});

  final List<ReviewLog> reviewLogs;
  final List<UserWord> userWords;
}

/// 导出文件集合：文件名 → 文本内容（写盘与分享由 DataExporter 承担）。
class ExportFiles {
  const ExportFiles(this.files);

  final Map<String, String> files;
}

/// 数据导出序列化器（纯 Dart，可单测；TECH_DOC §8.2 导出口径）。
///
/// - CSV：review_logs / user_words 各一个文件，UTF-8 带 BOM（Excel 中文不乱码），
///   首行表头，字段转义（引号/逗号/换行），时间戳 ISO 8601；
/// - JSON：单文件 `{version, exported_at, review_logs, user_words}`，
///   时间戳 epoch 毫秒（与库内一致，便于迁移回导）。
abstract final class DataExportFormatter {
  DataExportFormatter._();

  /// 当前导出结构版本（迁移回导工具按此解析）。
  static const int version = 1;

  static ExportFiles format(
    ExportPayload payload,
    ExportFormat format, {
    DateTime? exportedAt,
  }) {
    final now = exportedAt ?? DateTime.now();
    return switch (format) {
      ExportFormat.csv => ExportFiles({
        'review_logs.csv': _reviewLogsCsv(payload.reviewLogs),
        'user_words.csv': _userWordsCsv(payload.userWords),
      }),
      ExportFormat.json => ExportFiles({
        'export.json': _json(payload, now),
      }),
    };
  }

  static String _reviewLogsCsv(List<ReviewLog> logs) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(
      'id,user_id,wordbook_id,word_id,rating,reviewed_at,'
      'interval_days,stability,difficulty,session_id,session_type',
    );
    for (final log in logs) {
      buffer.writeln([
        _csv(log.id),
        _csv(log.userId),
        _csv(log.wordbookId),
        _csv(log.wordId),
        // 评分按 FSRS 语义数值 1–4 导出（review_logs.rating 存储值，§7.3）。
        _csv(log.rating.value),
        // 统一按 UTC 输出 ISO 8601，保证跨时区导出文件可复现。
        _csv(log.reviewedAt.toUtc().toIso8601String()),
        _csv(log.intervalDays),
        _csv(log.stability),
        _csv(log.difficulty),
        _csv(log.sessionId),
        _csv(log.sessionType.storageValue),
      ].join(','));
    }
    return buffer.toString();
  }

  static String _userWordsCsv(List<UserWord> words) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(
      'user_id,wordbook_id,word_id,state,status,due_date,'
      'stability,difficulty,reps,lapses,last_review_at,last_rating,'
      'elapsed_days,scheduled_days',
    );
    for (final word in words) {
      buffer.writeln([
        _csv(word.userId),
        _csv(word.wordbookId),
        _csv(word.wordId),
        _csv(word.state.storageValue),
        _csv(word.status.storageValue),
        _csv(word.dueDate?.toUtc().toIso8601String()),
        _csv(word.stability),
        _csv(word.difficulty),
        _csv(word.reps),
        _csv(word.lapses),
        _csv(word.lastReviewAt?.toUtc().toIso8601String()),
        _csv(word.lastRating),
        _csv(word.elapsedDays),
        _csv(word.scheduledDays),
      ].join(','));
    }
    return buffer.toString();
  }

  static String _json(ExportPayload payload, DateTime exportedAt) {
    return const JsonEncoder.withIndent('  ').convert({
      'version': version,
      'exported_at': exportedAt.toUtc().toIso8601String(),
      'review_logs': [
        for (final log in payload.reviewLogs)
          {
            'id': log.id,
            'user_id': log.userId,
            'wordbook_id': log.wordbookId,
            'word_id': log.wordId,
            'rating': log.rating.value,
            'reviewed_at': log.reviewedAt.millisecondsSinceEpoch,
            'interval_days': log.intervalDays,
            'stability': log.stability,
            'difficulty': log.difficulty,
            'session_id': log.sessionId,
            'session_type': log.sessionType.storageValue,
          },
      ],
      'user_words': [
        for (final word in payload.userWords)
          {
            'user_id': word.userId,
            'wordbook_id': word.wordbookId,
            'word_id': word.wordId,
            'state': word.state.storageValue,
            'status': word.status.storageValue,
            'due_date': word.dueDate?.millisecondsSinceEpoch,
            'stability': word.stability,
            'difficulty': word.difficulty,
            'reps': word.reps,
            'lapses': word.lapses,
            'last_review_at': word.lastReviewAt?.millisecondsSinceEpoch,
            'last_rating': word.lastRating,
            'elapsed_days': word.elapsedDays,
            'scheduled_days': word.scheduledDays,
          },
      ],
    });
  }

  /// CSV 字段转义：含逗号/引号/换行时用双引号包裹并转义内部引号。
  static String _csv(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
