import '../models/daily_plan.dart';
import '../models/daily_stats.dart';

/// 整日任务完成判定（TECH_DOC §5.5，2026-08-12 TD-07 收口口径）。
///
/// 判定规则：今日新词目标达成（`daily_stats.new_count ≥ 计划 new_word_count`）
/// **且** 今日计划内复习队列已清空（`daily_stats.review_count ≥ 计划
/// review_count`）；被复习软上限顺延的词未进入计划队列，不阻塞打卡
/// （保持原 due_date，次日自然排在最前，TECH_DOC §6.1）。
///
/// 纯逻辑、不读写数据库：输入为今日计划与当日统计，输出是否完成；
/// `daily_stats.completed` 置位由任务完成页（调用方）负责。
abstract final class DailyCheckinCalculator {
  DailyCheckinCalculator._();

  static bool isTodayComplete({
    required DailyPlan plan,
    required DailyStats stats,
  }) {
    return stats.newCount >= plan.newWordCount &&
        stats.reviewCount >= plan.reviewCount;
  }
}
