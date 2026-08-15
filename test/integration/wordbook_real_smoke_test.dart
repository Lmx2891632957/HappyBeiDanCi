/// 真实词库端到端冒烟（TECH_DOC §14.2）：导入内容管线产物 → 仓储读取 →
/// SessionDriver 真实学习 3 词 → 打卡统计。
///
/// 产物不在源码仓库（AGENTS §5.3），测试默认找 `tools/content_pipeline/work/
/// wordbook.db`（或环境变量 `HBDC_WORDBOOK_DB` 指定路径），缺失时跳过——
/// CI 无产物时不影响全绿，本地构建产物后可执行真实验证。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_review_log_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_session_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_stats_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_user_word_repository.dart';
import 'package:happy_bei_dan_ci/data/repositories/drift_wordbook_repository.dart';
import 'package:happy_bei_dan_ci/data/sources/wordbook_importer.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs/fsrs_engine.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/sessions/default_session_state_machine.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_driver.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';

import '../helpers/fixture.dart';

File? _locatePack() {
  final env = Platform.environment['HBDC_WORDBOOK_DB'];
  if (env != null && env.isNotEmpty) {
    final f = File(env);
    return f.existsSync() ? f : null;
  }
  final defaultPath = File(
    'tools/content_pipeline/work/wordbook.db',
  );
  return defaultPath.existsSync() ? defaultPath : null;
}

void main() {
  final pack = _locatePack();

  test('真实词库冒烟：导入 → 仓储读取 → 学习 3 词 → 打卡统计', () async {
    if (pack == null) {
      markTestSkipped('未找到真实词库产物，跳过（本地构建后可执行）');
      return;
    }
    final tempDir = await Directory.systemTemp.createTemp('wordbook_smoke');
    addTearDown(() => tempDir.delete(recursive: true));
    final db = openTestDb(tempDir, 'smoke');
    addTearDown(db.close);

    final importer = WordbookImporter(
      db,
      backupWriter: _NullBackupWriter(),
    );
    final result = await importer.importFromFile(pack);
    expect(result.changed, isTrue);
    expect(result.wordCount, greaterThanOrEqualTo(3500));

    final wordRepo = DriftWordbookRepository(db);
    final books = await wordRepo.getWordbooks();
    expect(books, hasLength(1));
    expect(books.single.level, 'gaokao');
    final remaining = await wordRepo.countRemainingNewWords(books.single.id);
    expect(remaining, greaterThanOrEqualTo(3500));

    // 首词内容质量抽查：音标、释义、例句署名齐备。
    final firstBatch = await wordRepo.getWordsByBook(books.single.id, limit: 5);
    expect(firstBatch, hasLength(5));
    for (final w in firstBatch.take(3)) {
      expect(w.phonetic, isNotEmpty);
      expect(w.meanings, isNotEmpty);
      expect(w.examples, isNotEmpty);
      expect(w.examples.first.attribution, isNotEmpty);
    }

    // 真实 SessionDriver 学习 3 词并完成，验证统计落库。
    final userWords = DriftUserWordRepository(db);
    final reviewLogs = DriftReviewLogRepository(db);
    final sessions = DriftSessionRepository(db);
    final stats = DriftStatsRepository(db);
    final driver = SessionDriver(
      stateMachine: DefaultSessionStateMachine(),
      scheduler: FsrsEngine(),
      userWords: userWords,
      reviewLogs: reviewLogs,
      sessions: sessions,
      stats: stats,
    );
    final wordIds = [for (final w in firstBatch) w.id];
    driver.startNewSession(
      sessionId: 'smoke-learn',
      type: SessionType.learning,
      wordbookId: books.single.id,
      wordIds: wordIds,
    );
    var card = driver.fetchCard();
    for (var i = 0; i < wordIds.length; i++) {
      expect(card, wordIds[i]);
      await driver.rate(Rating.good);
      if (i < wordIds.length - 1) {
        card = driver.fetchCard();
      }
    }
    await driver.finish();
    final statsAfter = await db.select(db.dailyStats).get();
    expect(statsAfter, hasLength(1));
    expect(statsAfter.single.newCount, wordIds.length);
  });
}

/// 冒烟测试不落备份文件（无升级场景，避免依赖 path_provider）。
class _NullBackupWriter implements BackupWriter {
  @override
  Future<File> write({required String name, required String content}) async {
    return File('/dev/null');
  }
}
