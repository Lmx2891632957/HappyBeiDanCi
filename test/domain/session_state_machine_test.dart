/// 会话状态机单测：状态转移、答错重排（≤2 次）、中断→恢复、完成后快照清理
/// （TECH_DOC §5.4，AGENTS §6.2/§7）。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/domain/scheduling/fsrs_scheduler.dart';
import 'package:happy_bei_dan_ci/domain/sessions/default_session_state_machine.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_snapshot.dart';
import 'package:happy_bei_dan_ci/domain/sessions/session_state_machine.dart';

DefaultSessionStateMachine startFresh({
  String sessionId = 's1',
  SessionType type = SessionType.learning,
  List<int> words = const [1, 2, 3],
}) {
  final machine = DefaultSessionStateMachine();
  machine.handle(
    SessionStarted.fresh(
      sessionId: sessionId,
      type: type,
      initialWordIds: words,
    ),
  );
  return machine;
}

void fetch(DefaultSessionStateMachine m) => m.handle(const CardFetched());

void rate(DefaultSessionStateMachine m, Rating rating) =>
    m.handle(CardRated(rating: rating));

void commit(DefaultSessionStateMachine m) => m.handle(const RatingCommitted());

void interrupt(DefaultSessionStateMachine m) =>
    m.handle(const SessionInterrupted());

void resume(DefaultSessionStateMachine m) => m.handle(const SessionResumed());

void finish(DefaultSessionStateMachine m) => m.handle(const SessionFinished());

List<int> snapWordIds(DefaultSessionStateMachine m) =>
    m.snapshot?.items.map((e) => e.wordId).toList() ?? const [];

/// 断言当前快照与期望的（position、剩余队列、每词剩余重排次数）一致。
void expectSnap(
  DefaultSessionStateMachine machine, {
  required int position,
  required List<int> wordIds,
  required Map<int, int> requeueLeft,
}) {
  final snap = machine.snapshot!;
  expect(snap.position, position);
  expect(snapWordIds(machine), wordIds);
  expect(snap.items.map((e) => e.seq).toList(), [
    for (var i = 0; i < wordIds.length; i++) i,
  ]);
  expect({for (final e in snap.items) e.wordId: e.requeueLeft}, requeueLeft);
}

void main() {
  group('状态转移', () {
    test('答对推进：Showing→Rating→Fetching 依序取卡，已答卡出队', () {
      final m = startFresh(words: [1, 2, 3]);
      expect(m.phase, SessionPhase.fetching);
      expectSnap(
        m,
        position: 0,
        wordIds: [1, 2, 3],
        requeueLeft: {
          1: kMaxRequeuePerSession,
          2: kMaxRequeuePerSession,
          3: kMaxRequeuePerSession,
        },
      );

      fetch(m);
      expect(m.phase, SessionPhase.showing);
      expect(m.currentWordId, 1);

      rate(m, Rating.good);
      expect(m.phase, SessionPhase.rating);
      expect(m.currentWordId, 1);

      commit(m);
      expect(m.phase, SessionPhase.fetching);
      expectSnap(m, position: 1, wordIds: [2, 3], requeueLeft: {2: 2, 3: 2});

      fetch(m);
      rate(m, Rating.good);
      commit(m);
      fetch(m);
      rate(m, Rating.good);
      commit(m);
      expect(m.phase, SessionPhase.fetching);
      expectSnap(m, position: 3, wordIds: [], requeueLeft: {});
    });

    test('答错重排：Again 回到队尾且 requeueLeft 减一', () {
      final m = startFresh(words: [1, 2]);
      fetch(m);
      rate(m, Rating.again);
      commit(m);
      expect(m.phase, SessionPhase.requeue);
      expectSnap(m, position: 1, wordIds: [2, 1], requeueLeft: {2: 2, 1: 1});

      fetch(m); // Requeue → Fetching
      expect(m.phase, SessionPhase.fetching);
      fetch(m); // Fetching → Showing
      expect(m.phase, SessionPhase.showing);
      expect(m.currentWordId, 2);

      rate(m, Rating.good);
      commit(m);
      expectSnap(m, position: 2, wordIds: [1], requeueLeft: {1: 1});
      fetch(m);
      expect(m.currentWordId, 1); // 重排卡在本次会话内至少再见一次
    });

    test('同一词连续答错最多重排 2 次，超限后按答对推进', () {
      final m = startFresh(words: [1]);

      // 第 1 次答错：重排（requeueLeft 2 → 1）。
      fetch(m);
      rate(m, Rating.again);
      commit(m);
      expect(m.phase, SessionPhase.requeue);
      expectSnap(m, position: 1, wordIds: [1], requeueLeft: {1: 1});
      fetch(m);
      fetch(m);

      // 第 2 次答错：重排（1 → 0）。
      rate(m, Rating.again);
      commit(m);
      expect(m.phase, SessionPhase.requeue);
      expectSnap(m, position: 2, wordIds: [1], requeueLeft: {1: 0});
      fetch(m);
      fetch(m);

      // 第 3 次答错：已超上限，仅移除不入队。
      rate(m, Rating.again);
      expect(m.phase, SessionPhase.rating);
      expectSnap(m, position: 2, wordIds: [1], requeueLeft: {1: 0});
      commit(m);
      expect(m.phase, SessionPhase.fetching);
      expectSnap(m, position: 3, wordIds: [], requeueLeft: {});
    });

    test('单卡会话：两次答错重排后答对完成', () {
      final m = startFresh(words: [1]);
      fetch(m);
      for (var i = 0; i < 2; i++) {
        rate(m, Rating.again);
        commit(m);
        expect(m.phase, SessionPhase.requeue);
        fetch(m);
        fetch(m);
      }
      expect(m.currentWordId, 1);
      rate(m, Rating.good);
      commit(m);
      expect(m.phase, SessionPhase.fetching);
      expectSnap(m, position: 3, wordIds: [], requeueLeft: {});
      finish(m);
      expect(m.phase, SessionPhase.done);
    });

    test('空队列直接完成：进入后即可 SessionFinished', () {
      final m = startFresh(words: []);
      expect(m.phase, SessionPhase.fetching);
      expect(m.snapshot!.items, isEmpty);
      finish(m);
      expect(m.phase, SessionPhase.done);
      expect(m.snapshot, isNull);
    });

    test('Hard/Good/Easy 均不触发重排', () {
      for (final rating in [Rating.hard, Rating.good, Rating.easy]) {
        final m = startFresh(words: [1, 2]);
        fetch(m);
        rate(m, rating);
        commit(m);
        expect(m.phase, SessionPhase.fetching, reason: 'rating=$rating');
        expectSnap(m, position: 1, wordIds: [2], requeueLeft: {2: 2});
      }
    });
  });

  group('中断与恢复（AGENTS §6.2）', () {
    test('Showing 阶段中断→恢复：学习会话队列一致、当前卡不变', () {
      final m = startFresh(type: SessionType.learning, words: [1, 2, 3]);
      fetch(m); // 展示 1
      interrupt(m);
      expect(m.phase, SessionPhase.paused);
      expectSnap(
        m,
        position: 0,
        wordIds: [1, 2, 3],
        requeueLeft: {1: 2, 2: 2, 3: 2},
      );

      resume(m);
      expect(m.phase, SessionPhase.showing);
      expect(m.currentWordId, 1);
      // 恢复后队列顺序、position、requeueLeft 与原快照一致。
      expectSnap(
        m,
        position: 0,
        wordIds: [1, 2, 3],
        requeueLeft: {1: 2, 2: 2, 3: 2},
      );

      // 恢复后继续作答，已答卡 1 不再出现。
      rate(m, Rating.good);
      commit(m);
      expectSnap(m, position: 1, wordIds: [2, 3], requeueLeft: {2: 2, 3: 2});
    });

    test('跨实例恢复（SessionStarted.resume）：以快照重建队列，已答卡不重复', () {
      final m = startFresh(type: SessionType.review, words: [1, 2, 3]);
      fetch(m);
      rate(m, Rating.good);
      commit(m); // 已消费 1
      fetch(m); // 展示 2
      final pausedSnap = m.snapshot!;
      expectSnap(m, position: 1, wordIds: [2, 3], requeueLeft: {2: 2, 3: 2});

      final restarted = DefaultSessionStateMachine();
      restarted.handle(SessionStarted.resume(pausedSnap));
      expect(restarted.phase, SessionPhase.fetching);
      expectSnap(
        restarted,
        position: 1,
        wordIds: [2, 3],
        requeueLeft: {2: 2, 3: 2},
      );
      fetch(restarted);
      expect(restarted.currentWordId, 2);

      rate(restarted, Rating.good);
      commit(restarted);
      fetch(restarted);
      expect(restarted.currentWordId, 3);
      rate(restarted, Rating.good);
      commit(restarted);
      expectSnap(restarted, position: 3, wordIds: [], requeueLeft: {});
      finish(restarted);
      expect(restarted.phase, SessionPhase.done);
    });

    test('Requeue 阶段中断→恢复：复习会话重排卡在队尾且 requeueLeft 减一', () {
      final m = startFresh(type: SessionType.review, words: [1, 2, 3]);
      fetch(m); // 1
      rate(m, Rating.again);
      commit(m); // → Requeue，1 追加到队尾
      expect(m.phase, SessionPhase.requeue);
      interrupt(m);
      expect(m.phase, SessionPhase.paused);
      expectSnap(
        m,
        position: 1,
        wordIds: [2, 3, 1],
        requeueLeft: {2: 2, 3: 2, 1: 1},
      );

      // 跨实例恢复：从 Requeue 快照重建，先展示队首下一张。
      final restarted = DefaultSessionStateMachine();
      restarted.handle(SessionStarted.resume(m.snapshot!));
      fetch(restarted);
      expect(restarted.currentWordId, 2);
      expectSnap(
        restarted,
        position: 1,
        wordIds: [2, 3, 1],
        requeueLeft: {2: 2, 3: 2, 1: 1},
      );

      // 原实例恢复后继续：3 之后重排卡 1 至少再见一次。
      resume(m);
      expect(m.phase, SessionPhase.showing);
      expect(m.currentWordId, 2);
      rate(m, Rating.good);
      commit(m);
      fetch(m);
      expect(m.currentWordId, 3);
      rate(m, Rating.good);
      commit(m);
      fetch(m);
      expect(m.currentWordId, 1);
      expect(m.phase, SessionPhase.showing);
    });

    test('中断快照不含已答卡；重排卡以队尾 occurrence 出现', () {
      final m = startFresh(words: [1, 2, 3]);
      fetch(m);
      rate(m, Rating.good);
      commit(m); // 1 已答，出队
      fetch(m);
      rate(m, Rating.again);
      commit(m); // 2 重排到队尾
      interrupt(m);
      expectSnap(m, position: 2, wordIds: [3, 2], requeueLeft: {3: 2, 2: 1});
    });

    test('Fetching 阶段队列为空时中断→恢复：进入 Fetching 等待完成', () {
      final m = startFresh(words: [1]);
      fetch(m);
      rate(m, Rating.good);
      commit(m); // fetching 且队列为空
      expect(m.phase, SessionPhase.fetching);
      interrupt(m);
      expect(m.phase, SessionPhase.paused);
      resume(m);
      expect(m.phase, SessionPhase.fetching);
      expectSnap(m, position: 1, wordIds: [], requeueLeft: {});
      finish(m);
      expect(m.phase, SessionPhase.done);
    });

    test('快照为独立副本，外部修改不影响状态机', () {
      final m = startFresh(words: [1, 2]);
      fetch(m);
      interrupt(m);
      final snap = m.snapshot!;
      snap.items.add(
        const SessionItemSnapshot(wordId: 99, seq: 2, requeueLeft: 2),
      );
      resume(m);
      expectSnap(m, position: 0, wordIds: [1, 2], requeueLeft: {1: 2, 2: 2});
    });
  });

  group('完成后快照清理', () {
    test('Done 后 snapshot 与 currentWordId 均为 null', () {
      final m = startFresh(words: [1]);
      fetch(m);
      rate(m, Rating.good);
      commit(m);
      expect(m.snapshot, isNotNull);
      finish(m);
      expect(m.phase, SessionPhase.done);
      expect(m.snapshot, isNull);
      expect(m.currentWordId, isNull);
    });
  });

  group('学习与复习共用同一状态机', () {
    test('相同事件序列产生相同阶段、当前卡与队列', () {
      List<(SessionPhase, int?, int, List<int>)> run(SessionType type) {
        final m = startFresh(type: type, words: [1, 2, 3]);
        final log = <(SessionPhase, int?, int, List<int>)>[];
        void logState() =>
            log.add((m.phase, m.currentWordId, m.position, snapWordIds(m)));
        logState();
        fetch(m);
        logState();
        rate(m, Rating.again);
        logState();
        commit(m);
        logState();
        fetch(m);
        logState();
        fetch(m);
        logState();
        rate(m, Rating.good);
        logState();
        commit(m);
        logState();
        interrupt(m);
        logState();
        resume(m);
        logState();
        rate(m, Rating.good);
        commit(m);
        logState();
        fetch(m);
        logState();
        rate(m, Rating.good);
        commit(m);
        logState();
        finish(m);
        logState();
        return log;
      }

      // 记录内的 List 字段按引用比较，逐字段断言才能做深度比较。
      final learning = run(SessionType.learning);
      final review = run(SessionType.review);
      expect(learning.length, review.length);
      for (var i = 0; i < learning.length; i++) {
        expect(learning[i].$1, review[i].$1);
        expect(learning[i].$2, review[i].$2);
        expect(learning[i].$3, review[i].$3);
        expect(learning[i].$4, review[i].$4);
      }
    });
  });

  group('非法转移与非法输入', () {
    test('SessionStarted 只能从 Idle 发起', () {
      final m = startFresh(words: [1]);
      expect(
        () => m.handle(
          SessionStarted.fresh(
            sessionId: 'x',
            type: SessionType.learning,
            initialWordIds: const [1],
          ),
        ),
        throwsStateError,
      );
    });

    test('CardFetched 仅允许在 Fetching/Requeue', () {
      final m = startFresh(words: [1]);
      fetch(m); // showing
      expect(() => fetch(m), throwsStateError);
    });

    test('CardRated 仅允许在 Showing', () {
      final m = startFresh(words: [1]);
      expect(() => rate(m, Rating.good), throwsStateError);
    });

    test('RatingCommitted 仅允许在 Rating', () {
      final m = startFresh(words: [1]);
      expect(() => commit(m), throwsStateError);
    });

    test('SessionFinished 仅允许 Fetching 且队列为空', () {
      final m = startFresh(words: [1]);
      expect(() => finish(m), throwsStateError); // fetching 但队列非空
      fetch(m);
      expect(() => finish(m), throwsStateError); // showing
    });

    test('SessionInterrupted 仅允许在活动阶段', () {
      final m = DefaultSessionStateMachine();
      expect(() => interrupt(m), throwsStateError); // idle
      m.handle(
        SessionStarted.fresh(
          sessionId: 's',
          type: SessionType.learning,
          initialWordIds: const [1],
        ),
      );
      fetch(m);
      rate(m, Rating.good);
      commit(m);
      finish(m);
      expect(() => interrupt(m), throwsStateError); // done
    });

    test('SessionResumed 仅允许在 Paused', () {
      final m = startFresh(words: [1]);
      expect(() => resume(m), throwsStateError);
    });

    test('初始队列含重复词被拒绝', () {
      final m = DefaultSessionStateMachine();
      expect(
        () => m.handle(
          SessionStarted.fresh(
            sessionId: 's',
            type: SessionType.learning,
            initialWordIds: const [1, 1],
          ),
        ),
        throwsArgumentError,
      );
    });

    test('恢复快照 seq 不连续、requeueLeft 为负或 position 为负被拒绝', () {
      SessionSnapshot snapWith(
        List<SessionItemSnapshot> items, {
        int position = 0,
      }) => SessionSnapshot(
        sessionId: 's',
        type: SessionType.learning,
        position: position,
        items: items,
      );

      final m = DefaultSessionStateMachine();
      expect(
        () => m.handle(
          SessionStarted.resume(
            snapWith(const [
              SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
              SessionItemSnapshot(wordId: 2, seq: 2, requeueLeft: 2),
            ]),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => m.handle(
          SessionStarted.resume(
            snapWith(const [
              SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: -1),
            ]),
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => m.handle(
          SessionStarted.resume(
            snapWith(const [
              SessionItemSnapshot(wordId: 1, seq: 0, requeueLeft: 2),
            ], position: -1),
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
