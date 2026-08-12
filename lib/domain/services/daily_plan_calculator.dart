import '../models/daily_plan.dart';
import '../models/user_word.dart';

/// 每日计划计算契约（TECH_DOC §6.1 常规模式）。
///
/// 纯逻辑：所有输入（每日目标、剩余新词数、到期词列表、软上限、今日零点）
/// 均由调用方从仓储获取后传入，本层不读写数据库；高考倒计时模式（§6.3）
/// 属 M3，不在本契约范围内。
abstract interface class DailyPlanCalculator {
  /// 计算今日计划。
  ///
  /// [dailyGoal] 每日新词目标；[remainingNewWords] 词书剩余新词数；
  /// [dueWords] 到期复习词（须已按 `due_date <= 今日结束` 过滤）；
  /// [cap] 复习软上限，null 表示关闭；[todayStart] 今日零点
  /// （调度时区换算见 TECH_DOC §6.2/§18）。
  DailyPlan calculate({
    required int dailyGoal,
    required int remainingNewWords,
    required List<UserWord> dueWords,
    int? cap,
    required DateTime todayStart,
  });
}
