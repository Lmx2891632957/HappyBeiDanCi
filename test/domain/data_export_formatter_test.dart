/// 数据导出序列化测试（TECH_DOC §8.2 导出口径）：
/// CSV 表头/转义/BOM、JSON 结构与 epoch 毫秒时间戳。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/models/review_log.dart';
import 'package:happy_bei_dan_ci/domain/models/user_word.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/services/data_export_formatter.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';

void main() {
  final logs = [
    ReviewLog(
      id: 1,
      userId: 0,
      wordbookId: 1,
      wordId: 2,
      rating: Rating.good,
      reviewedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
      intervalDays: 3,
      stability: 5.2,
      difficulty: 4.1,
      sessionId: 's1',
      sessionType: SessionType.learning,
    ),
    ReviewLog(
      id: 2,
      userId: 0,
      wordbookId: 1,
      wordId: 3,
      rating: Rating.again,
      reviewedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_100_000),
      // 含逗号/引号的字段验证转义。
      sessionId: 'a,"b"',
      sessionType: SessionType.review,
    ),
  ];
  final words = [
    UserWord(
      userId: 0,
      wordbookId: 1,
      wordId: 2,
      state: WordLearningState.review,
      status: WordStatus.review,
      dueDate: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
      stability: 5.2,
      difficulty: 4.1,
      reps: 2,
      lapses: 0,
      lastReviewAt: DateTime.fromMillisecondsSinceEpoch(1_690_000_000_000),
      lastRating: 3,
      elapsedDays: 1.0,
      scheduledDays: 3.0,
    ),
  ];
  final payload = ExportPayload(reviewLogs: logs, userWords: words);

  test('CSV：BOM 表头 + 字段转义 + ISO 时间戳 + 评分序号', () {
    final files = DataExportFormatter.format(
      payload,
      ExportFormat.csv,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_200_000),
    );

    final reviewCsv = files.files['review_logs.csv']!;
    expect(reviewCsv.startsWith('\uFEFF'), isTrue);
    final lines = reviewCsv.split('\n');
    expect(
      lines[0],
      '\uFEFFid,user_id,wordbook_id,word_id,rating,reviewed_at,'
      'interval_days,stability,difficulty,session_id,session_type',
    );
    // 第二行 = id=1 的日志（Good=3 评分序号、ISO 时间戳）。
    expect(lines[1], contains('1,0,1,2,3,2023-11-14T22:13:20.000Z'));
    // 第三行 = id=2：含逗号/引号的 session_id 被双引号包裹并转义。
    expect(lines[2], contains('"a,""b"""'));

    final wordsCsv = files.files['user_words.csv']!;
    expect(wordsCsv.startsWith('\uFEFF'), isTrue);
    expect(
      wordsCsv.split('\n').first,
      '\uFEFFuser_id,wordbook_id,word_id,state,status,due_date,'
      'stability,difficulty,reps,lapses,last_review_at,last_rating,'
      'elapsed_days,scheduled_days',
    );
    expect(
      wordsCsv.split('\n')[1],
      contains('review,review,2023-11-14T22:13:20.000Z'),
    );
  });

  test('JSON：version/exported_at/review_logs/user_words，时间戳 epoch 毫秒', () {
    final files = DataExportFormatter.format(
      payload,
      ExportFormat.json,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_200_000),
    );
    final json = files.files['export.json']!;
    expect(json, contains('"version": 1'));
    expect(json, contains('"exported_at": "2023-11-14T22:16:40.000Z"'));
    expect(json, contains('"reviewed_at": 1700000000000'));
    expect(json, contains('"due_date": 1700000000000'));
    expect(json, contains('"session_type": "learning"'));
    expect(json, contains('"state": "review"'));
  });

  test('空数据导出：CSV 仅表头、JSON 空数组', () {
    final empty = const ExportPayload(reviewLogs: [], userWords: []);
    final files = DataExportFormatter.format(
      empty,
      ExportFormat.json,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    expect(files.files['export.json'], contains('"review_logs": []'));
    expect(files.files['export.json'], contains('"user_words": []'));

    final csvFiles = DataExportFormatter.format(
      empty,
      ExportFormat.csv,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    expect(csvFiles.files['review_logs.csv']!.split('\n'), hasLength(2));
    expect(csvFiles.files['user_words.csv']!.split('\n'), hasLength(2));
  });
}
