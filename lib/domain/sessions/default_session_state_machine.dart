import '../scheduling/fsrs_scheduler.dart';
import 'session_snapshot.dart';
import 'session_state_machine.dart';

/// 会话内每词最大重排次数（TECH_DOC §18：防止单次会话无限循环）。
const int kMaxRequeuePerSession = 2;

/// 学习/复习会话状态机实现（TECH_DOC §5.4 状态图）。
///
/// 纯逻辑：不读写数据库、不执行 FSRS 计算、不生成随机。队列在内存中维护为
/// "剩余队列"，每个词至多一个待展示 occurrence：答对时移除队首；答错（Again）
/// 且仍有重排次数时移除队首并追加到队尾、重排次数减一；重排次数耗尽后再答错
/// 按答对推进（仅移除）。学习与复习共用本实现，[SessionType] 仅作记录。
class DefaultSessionStateMachine implements SessionStateMachine {
  DefaultSessionStateMachine();

  SessionPhase _phase = SessionPhase.idle;
  String? _sessionId;
  SessionType? _type;

  /// 剩余队列：待展示卡，队首即下一张；不含已消费卡，词不重复。
  final List<int> _queue = [];

  /// 每词剩余重排次数（初始 [kMaxRequeuePerSession]，每次重排递减 1）。
  final Map<int, int> _requeueLeft = {};

  /// 已消费卡数（进度，sessions.position 语义，TECH_DOC §5.4）。
  int _position = 0;

  /// CardRated 时记录的重排决定，由 RatingCommitted 消费后复位。
  bool _pendingRequeue = false;

  @override
  SessionPhase get phase => _phase;

  @override
  SessionSnapshot? get snapshot => switch (_phase) {
    SessionPhase.idle || SessionPhase.done => null,
    _ => _buildSnapshot(),
  };

  @override
  int? get currentWordId => switch (_phase) {
    SessionPhase.showing ||
    SessionPhase.rating ||
    SessionPhase.requeue => _queue.isEmpty ? null : _queue.first,
    _ => null,
  };

  @override
  int get position => _position;

  @override
  void handle(SessionEvent event) {
    switch (event) {
      case SessionStarted():
        _start(event);
      case CardFetched():
        _fetch();
      case CardRated():
        _rate(event);
      case RatingCommitted():
        _commit();
      case SessionInterrupted():
        _interrupt();
      case SessionResumed():
        _resume();
      case SessionFinished():
        _finish();
    }
  }

  void _start(SessionStarted event) {
    if (_phase != SessionPhase.idle) {
      throw StateError('会话已开始，不能重复进入（phase=$_phase）');
    }
    final snapshot = event.snapshot;
    if (snapshot != null) {
      _restoreFromSnapshot(snapshot);
    } else {
      final sessionId = event.sessionId;
      final type = event.type;
      final words = event.initialWordIds;
      if (sessionId == null ||
          sessionId.isEmpty ||
          type == null ||
          words == null) {
        throw ArgumentError('新会话必须提供非空 sessionId、type 与 initialWordIds');
      }
      _sessionId = sessionId;
      _type = type;
      _queue
        ..clear()
        ..addAll(words);
      _validateNoDuplicateWords(_queue);
      _requeueLeft.clear();
      for (final wordId in _queue) {
        _requeueLeft[wordId] = kMaxRequeuePerSession;
      }
      _position = 0;
      _pendingRequeue = false;
    }
    _phase = SessionPhase.fetching;
  }

  /// 以快照全量重建队列（TD-07）：items 是剩余队列的唯一编码，恢复不依赖
  /// 其他信息；position 仅作进度恢复，下一张卡恒为重建后队首。
  void _restoreFromSnapshot(SessionSnapshot snapshot) {
    if (snapshot.position < 0) {
      throw ArgumentError.value(snapshot.position, 'position', '已消费卡数不能为负数');
    }
    final sorted = [...snapshot.items]..sort((a, b) => a.seq.compareTo(b.seq));
    final wordIds = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      if (item.seq != i) {
        throw ArgumentError.value(item.seq, 'seq', 'seq 必须为 0 起连续下标');
      }
      if (item.requeueLeft < 0) {
        throw ArgumentError.value(
          item.requeueLeft,
          'requeueLeft',
          '剩余重排次数不能为负数',
        );
      }
      wordIds.add(item.wordId);
    }
    _validateNoDuplicateWords(wordIds);
    _sessionId = snapshot.sessionId;
    _type = snapshot.type;
    _queue
      ..clear()
      ..addAll(wordIds);
    _requeueLeft.clear();
    for (final item in sorted) {
      _requeueLeft[item.wordId] = item.requeueLeft;
    }
    _position = snapshot.position;
    _pendingRequeue = false;
  }

  void _validateNoDuplicateWords(List<int> wordIds) {
    final seen = <int>{};
    for (final wordId in wordIds) {
      if (wordId < 0) {
        throw ArgumentError.value(wordId, 'wordId', '词 ID 不能为负数');
      }
      if (!seen.add(wordId)) {
        throw ArgumentError.value(wordId, 'wordId', '队列中不能出现重复词');
      }
    }
  }

  void _fetch() {
    if (_phase == SessionPhase.requeue) {
      // 重排追加已在 RatingCommitted 完成，这里只推进阶段（TECH_DOC §5.4）。
      _phase = SessionPhase.fetching;
      return;
    }
    if (_phase != SessionPhase.fetching) {
      throw StateError('CardFetched 仅允许在 Fetching/Requeue 阶段（phase=$_phase）');
    }
    if (_queue.isEmpty) {
      throw StateError('队列为空，应发送 SessionFinished 完成会话');
    }
    _phase = SessionPhase.showing;
  }

  void _rate(CardRated event) {
    if (_phase != SessionPhase.showing) {
      throw StateError('CardRated 仅允许在 Showing 阶段（phase=$_phase）');
    }
    final wordId = _queue.first;
    final left = _requeueLeft[wordId] ?? 0;
    // 重排判定 = Again 且仍有剩余次数；Hard/Good/Easy 一律不重排（TECH_DOC §5.4）。
    _pendingRequeue = event.rating == Rating.again && left > 0;
    _phase = SessionPhase.rating;
  }

  void _commit() {
    if (_phase != SessionPhase.rating) {
      throw StateError('RatingCommitted 仅允许在 Rating 阶段（phase=$_phase）');
    }
    final wordId = _queue.removeAt(0);
    _position++;
    if (_pendingRequeue) {
      // 先消费队首 occurrence 再追加到队尾：既满足"至少再见一次"，又保证
      // 每个词至多一个待展示 occurrence（session_items 一行一卡，§8.1）。
      final left = _requeueLeft[wordId]!;
      _requeueLeft[wordId] = left - 1;
      _queue.add(wordId);
      _phase = SessionPhase.requeue;
    } else {
      _phase = SessionPhase.fetching;
    }
    _pendingRequeue = false;
  }

  void _interrupt() {
    switch (_phase) {
      case SessionPhase.fetching:
      case SessionPhase.showing:
      case SessionPhase.rating:
      case SessionPhase.requeue:
        _phase = SessionPhase.paused;
      default:
        throw StateError('SessionInterrupted 仅允许在活动阶段（phase=$_phase）');
    }
  }

  void _resume() {
    if (_phase != SessionPhase.paused) {
      throw StateError('SessionResumed 仅允许在 Paused 阶段（phase=$_phase）');
    }
    // 读取快照重建队列：Paused 时快照即当前状态，恢复以快照为准（TD-07）。
    _restoreFromSnapshot(_buildSnapshot());
    // 剩余队列非空 → 重新展示队首卡；为空 → 等待 SessionFinished（§5.4）。
    _phase = _queue.isEmpty ? SessionPhase.fetching : SessionPhase.showing;
  }

  void _finish() {
    if (_phase != SessionPhase.fetching || _queue.isNotEmpty) {
      throw StateError('SessionFinished 仅允许在 Fetching 且队列为空时（phase=$_phase）');
    }
    _phase = SessionPhase.done;
    _sessionId = null;
    _type = null;
    _queue.clear();
    _requeueLeft.clear();
    _position = 0;
  }

  SessionSnapshot _buildSnapshot() {
    return SessionSnapshot(
      sessionId: _sessionId!,
      type: _type!,
      position: _position,
      items: [
        for (var i = 0; i < _queue.length; i++)
          SessionItemSnapshot(
            wordId: _queue[i],
            seq: i,
            requeueLeft: _requeueLeft[_queue[i]] ?? 0,
          ),
      ],
    );
  }
}
