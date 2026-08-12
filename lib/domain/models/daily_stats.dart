/// 每日统计领域模型（TECH_DOC §8.1 daily_stats 表，打卡/曲线数据）。
class DailyStats {
  const DailyStats({
    required this.day,
    this.newCount = 0,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.completed = 0,
  });

  /// 日期键 YYYY-MM-DD（本地日边界）。
  final String day;
  final int newCount;
  final int reviewCount;

  /// 复习正确数（rating ≥ 3 记正确，TECH_DOC §6.4）。
  final int correctCount;

  /// 当日任务完成标记（1=完成，用于连续打卡计算）。
  final int completed;
}
