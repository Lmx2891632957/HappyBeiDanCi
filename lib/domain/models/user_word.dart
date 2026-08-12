/// 用户学习状态领域模型（TECH_DOC §8.1 user_words 表，FSRS 调度核心）。
class UserWord {
  const UserWord({
    this.userId = 0,
    required this.wordbookId,
    required this.wordId,
    required this.state,
    required this.status,
    this.dueDate,
    this.stability = 0,
    this.difficulty = 0,
    this.reps = 0,
    this.lapses = 0,
    this.lastReviewAt,
    this.lastRating,
    this.elapsedDays,
    this.scheduledDays,
  });

  /// 本地单用户预留（TECH_DOC §8.1）。
  final int userId;
  final int wordbookId;
  final int wordId;

  /// FSRS 记忆阶段（new/learning/review/relearning）。
  final WordLearningState state;

  /// 业务层派生状态（learning/review/mature）。
  final WordStatus status;
  final DateTime? dueDate;
  final double stability;
  final double difficulty;
  final int reps;
  final int lapses;
  final DateTime? lastReviewAt;
  final int? lastRating;
  final double? elapsedDays;
  final double? scheduledDays;
}

/// FSRS 记忆阶段（TECH_DOC §7.2）。
enum WordLearningState {
  new_,
  learning,
  review,
  relearning;

  /// 存储层文本值（user_words.state）。
  String get storageValue => switch (this) {
    WordLearningState.new_ => 'new',
    WordLearningState.learning => 'learning',
    WordLearningState.review => 'review',
    WordLearningState.relearning => 'relearning',
  };
}

/// 业务层派生状态（TECH_DOC §4 核心概念）。
enum WordStatus {
  learning,
  review,
  mature;

  String get storageValue => switch (this) {
    WordStatus.learning => 'learning',
    WordStatus.review => 'review',
    WordStatus.mature => 'mature',
  };
}
