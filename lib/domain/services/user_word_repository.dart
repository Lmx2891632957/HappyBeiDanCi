import '../models/user_word.dart';

/// 用户学习状态仓储契约（FSRS 调度核心数据）。
abstract interface class UserWordRepository {
  /// 查询到期复习词（due_date <= [todayEnd]），排序与软上限由队列构建器负责。
  Future<List<UserWord>> getDueWords({required DateTime todayEnd, int? limit});

  Future<UserWord?> getWord({required int userId, required int wordbookId, required int wordId});

  /// 评分后 upsert；批量写日志应合并事务（TECH_DOC §8.2）。
  Future<void> upsert(UserWord word);
}
