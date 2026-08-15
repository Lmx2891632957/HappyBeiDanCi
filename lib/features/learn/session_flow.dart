import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/logger.dart';
import '../../domain/models/word.dart';
import '../../domain/scheduling/fsrs_scheduler.dart';
import '../../domain/sessions/session_driver.dart';
import '../../domain/sessions/session_snapshot.dart';
import '../../domain/sessions/session_state_machine.dart';
import 'widgets/rating_buttons.dart';
import 'widgets/session_card.dart';

/// 学习/复习共用会话流程（TECH_DOC §5.4 驱动契约的 UI 调用方）。
///
/// 一场会话一个 [SessionDriver] 实例：新会话传入 [initialWords]（学习=今日新词、
/// 复习=到期词），恢复会话传入 [resumeSnapshot]（TD-07：快照是恢复的唯一依据，
/// 由调用方经 SessionRepository.load 取得）。流程：驱动启动 → 逐卡
/// fetchCard/rate（Again 重排由驱动返回 requeued，UI 继续 fetchCard 即可）
/// → 队列空 finish → 跳转完成页；返回/退后台 interrupt 持久化快照（T-05）。
class SessionFlow extends ConsumerStatefulWidget {
  const SessionFlow({
    super.key,
    required this.type,
    required this.wordbookId,
    this.initialWords,
    this.resumeSnapshot,
  });

  final SessionType type;
  final int wordbookId;

  /// 新会话初始队列（学习/复习各自按计划取词后传入）；恢复会话时传 null。
  final List<Word>? initialWords;

  /// 恢复会话的快照（非空时以快照重建队列，忽略 [initialWords]）。
  final SessionSnapshot? resumeSnapshot;

  @override
  ConsumerState<SessionFlow> createState() => _SessionFlowState();
}

class _SessionFlowState extends ConsumerState<SessionFlow> {
  late final SessionDriver _driver;
  final Map<int, Word> _words = {};
  final Random _random = Random();

  bool _loading = true;
  String? _error;
  bool _finishFailed = false;

  /// 评分失败（区别于加载/完成失败）：文案用 sessionRateFailed（缺陷三）。
  bool _rateFailed = false;
  int? _currentWordId;
  String? _feedback;

  /// 评分进行中（防重复提交；同时是中断与评分互斥的同步标志）。
  bool _submitting = false;

  /// 中断（快照保存）进行中：期间评分入口直接短路，避免评分落到已中断的
  /// 状态机（缺陷二互斥：_rate 与 _interrupt 同一时刻至多一个在推进）。
  bool _interrupting = false;

  /// 进行中的评分 future：中断发起时先等其完成再保存快照，防止"评分已
  /// 落库、队列未推进"的部分提交（状态机停在 Rating，恢复后重复作答）。
  Future<void>? _pendingRate;
  bool _finished = false;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _driver = ref.read(sessionDriverProvider);
    final resume = widget.resumeSnapshot;
    if (resume != null) {
      _driver.resumeSession(resume, wordbookId: widget.wordbookId);
    } else {
      final words = widget.initialWords ?? const [];
      _driver.startNewSession(
        sessionId: _newSessionId(),
        type: widget.type,
        wordbookId: widget.wordbookId,
        wordIds: [for (final w in words) w.id],
      );
      _words.addAll({for (final w in words) w.id: w});
    }
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleState);
    _init();
  }

  Future<void> _init() async {
    try {
      // 恢复路径：快照只含 wordId，需按 ID 批量取词（getWordsByIds，§8.3）。
      if (widget.resumeSnapshot != null) {
        final ids = [
          for (final item in widget.resumeSnapshot!.items) item.wordId,
        ];
        final loaded = await ref
            .read(wordbookRepositoryProvider)
            .getWordsByIds(ids);
        _words.addAll({for (final w in loaded) w.id: w});
      }
      if (!mounted) {
        return;
      }
      // 恢复快照 items 为空（队列已清空但未 finish）是合法快照（§5.4）：
      // 直接完成会话，避免 fetchCard 对空队列抛错。
      if (_driver.phase == SessionPhase.fetching &&
          (_driver.snapshot?.items.isEmpty ?? true)) {
        await _finishAndNavigate();
        return;
      }
      _currentWordId = _driver.fetchCard();
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  /// 用户作答入口：先做互斥与阶段防御，再执行评分（实际逻辑见 [_rateInner]）。
  ///
  /// 互斥（缺陷二）：评分与中断共用 `_submitting`/`_interrupting` 两个标志，
  /// 任一进行中另一入口直接短路；评分进行中发起中断会先等评分完成
  /// （[_interrupt] 内 await [_pendingRate]），保证状态机事件严格串行。
  Future<void> _rate(Rating rating) async {
    if (_submitting || _interrupting) {
      return;
    }
    // 防御：评分仅允许在 Showing（TECH_DOC §5.4 状态图）。正常时序下
    // resumed 生命周期已把会话恢复为 Showing，此处仅兜底异常时序（如恢复
    // 失败、中断与恢复竞态），不向用户抛状态机 StateError——Paused 先恢复
    // 会话再继续评分；其余阶段（如评分失败残留的 Rating）静默忽略本次
    // 点击，错误文案已在失败时展示，用户返回会 interrupt 保存快照。
    if (_driver.phase != SessionPhase.showing) {
      if (_driver.phase == SessionPhase.paused) {
        await _onResumed();
      }
      if (!mounted || _driver.phase != SessionPhase.showing) {
        return;
      }
    }
    _submitting = true;
    final future = _rateInner(rating);
    _pendingRate = future;
    try {
      await future;
    } finally {
      _submitting = false;
      _pendingRate = null;
    }
  }

  /// 评分主体：CardRated → FSRS 调度 + 落库 → RatingCommitted → 取下一张卡。
  Future<void> _rateInner(Rating rating) async {
    final l10n = AppLocalizations.of(context);
    final wordId = _currentWordId;
    final word = wordId == null ? null : _words[wordId];
    try {
      await _driver.rate(rating);
      final feedback = switch (rating) {
        Rating.again => l10n.feedbackAgain(word?.word ?? ''),
        Rating.hard => l10n.feedbackHard(word?.word ?? ''),
        Rating.good => l10n.feedbackGood(word?.word ?? ''),
        // UI 三键不含 Easy（§7.3 认识=Good 为最高档），防御性兜底。
        Rating.easy => l10n.feedbackGood(word?.word ?? ''),
      };
      // 队列清空（fetching 且无剩余项）→ 完成会话；否则继续取下一张卡。
      // Again 重排时驱动进入 requeue，重排卡已追加队尾，同样由 fetchCard
      // 取出（requeued 语义在驱动内实现，UI 无需分支，TECH_DOC §5.4）。
      if (_driver.phase == SessionPhase.fetching &&
          (_driver.snapshot?.items.isEmpty ?? true)) {
        setState(() => _feedback = feedback);
        await _finishAndNavigate();
        return;
      }
      final next = _driver.fetchCard();
      if (!mounted) {
        return;
      }
      setState(() {
        _currentWordId = next;
        _feedback = feedback;
        _error = null;
        _rateFailed = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      // 评分异常（如数据库损坏导致取卡失败）：状态机已进入 Rating，
      // 直接重试不安全，提示用户返回（返回路径会 interrupt 保存快照）；
      // 文案与加载失败区分（sessionRateFailed，缺陷三）。
      setState(() {
        _error = '$error';
        _rateFailed = true;
      });
    }
  }

  Future<void> _finishAndNavigate() async {
    if (_finished) {
      return;
    }
    _finished = true;
    try {
      await _driver.finish();
      // 完成会改变今日计划与快照状态：返回今日页前失效相关 provider，
      // 避免首页复用会话开始前的缓存（待学/待复习与继续入口保持最新）。
      ref.invalidate(todayPlanProvider);
      ref.invalidate(unfinishedSessionsProvider);
      if (!mounted) {
        return;
      }
      context.pushReplacement('/results');
    } catch (error) {
      // finish 持久化失败向上抛出且可幂等重试（§5.4 驱动契约）：保留完成
      // 数据，重试不会重复计数；页面展示"重试"按钮。
      if (!mounted) {
        return;
      }
      _finished = false;
      setState(() {
        _error = '$error';
        _finishFailed = true;
      });
    }
  }

  /// 中断：快照保存失败时重试一次（驱动已进入 Paused，幂等重存，§5.4）；
  /// 仍失败记录日志并放行返回（避免把用户困在页面，T-05 由驱动抛错语义兜底，
  /// 下次进入时快照缺失会提示重新开始而非静默继续）。
  ///
  /// 与评分互斥（缺陷二）：`_interrupting` 标志让并发的中断调用与评分入口
  /// 直接短路；发起时若评分进行中（[_pendingRate] 非空）先等其完成——评分
  /// 完成后队列已推进，再中断保存的快照才与落库一致，避免"评分已落库、
  /// 队列未推进"的部分提交（中断停在 Rating 阶段，恢复后同一卡重复作答）。
  Future<void> _interrupt() async {
    if (_interrupting) {
      return;
    }
    _interrupting = true;
    try {
      if (_driver.phase == SessionPhase.idle ||
          _driver.phase == SessionPhase.done) {
        return;
      }
      final pending = _pendingRate;
      if (pending != null) {
        await pending;
      }
      if (_driver.phase == SessionPhase.idle ||
          _driver.phase == SessionPhase.done) {
        // 等待评分期间会话已完成（finish 清空元数据）：无需再中断。
        return;
      }
      try {
        await _driver.interrupt();
        _invalidateHomeViews();
      } catch (error) {
        try {
          await _driver.interrupt();
          _invalidateHomeViews();
        } catch (error2) {
          AppLogger.error('会话中断快照保存失败（重试后仍失败）', error2);
        }
      }
    } finally {
      _interrupting = false;
    }
  }

  /// 切回前台恢复：退后台时 [_interrupt] 已把状态机转入 Paused 并保存快照，
  /// 返回前台后从 Paused 恢复（SessionResumed，TECH_DOC §5.4 状态图）。
  ///
  /// 与跨实例恢复（resumeSession）不同：同一驱动实例内状态机内存队列即权威
  /// （Paused 时快照即当前状态），无需重新读库；剩余队列非空 → 恢复展示队首
  /// 卡，为空（合法快照，§5.4）→ 直接完成会话。缺陷一治本：此前无 resumed
  /// 分支，切回前台后用户继续评分会向 Paused 状态机发 CardRated 抛 StateError。
  Future<void> _onResumed() async {
    if (!mounted || _driver.phase != SessionPhase.paused) {
      // 未中断（如仅拉下通知栏/打开最近任务后返回）或页面已销毁：无需恢复。
      return;
    }
    try {
      _driver.resume();
      if (_driver.phase == SessionPhase.fetching) {
        // 队列已清空但未 finish 的合法快照（§5.4）：直接完成会话。
        await _finishAndNavigate();
        return;
      }
      if (!mounted) {
        return;
      }
      // Showing：队首卡即中断时的当前卡，恢复展示并清掉中断前的反馈/错误。
      setState(() {
        _currentWordId = _driver.currentWordId;
        _feedback = null;
        _error = null;
        _rateFailed = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '$error');
    }
  }

  /// 中断保存成功后失效今日页相关 provider（评分已落库、快照已新增，
  /// 返回今日页时应重算计划并展示"继续"入口，TECH_DOC §5.1）。
  void _invalidateHomeViews() {
    if (!mounted) {
      // dispose 兜底路径（widget 已销毁）：无需失效，首页重建时会重新加载。
      return;
    }
    ref.invalidate(todayPlanProvider);
    ref.invalidate(unfinishedSessionsProvider);
  }

  void _onLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // 退后台：尽力保存快照（T-05）；失败已在 _interrupt 内记录日志。
      unawaited(_interrupt());
    } else if (state == AppLifecycleState.resumed) {
      // 切回前台：若退后台时已中断（状态机 Paused），恢复会话使评分可继续
      //（缺陷一治本：此前无 resumed 分支，继续评分向 Paused 状态机发
      // CardRated 抛 StateError，只能退出重进）。
      unawaited(_onResumed());
    }
  }

  String _newSessionId() {
    // 骨架阶段不引入 uuid 依赖（AGENTS §6.4）：时间戳 + 随机后缀保证
    // 单设备内唯一；正式引入 uuid 包时替换。
    return 's-${DateTime.now().microsecondsSinceEpoch}-'
        '${_random.nextInt(0x7fffffff)}';
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    // 兜底：非 PopScope 覆盖的导航（如路由被替换）离开页面时尽力保存快照。
    unawaited(_interrupt());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.type == SessionType.learning
        ? l10n.learnTitle
        : l10n.reviewTitle;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _interrupt();
        if (context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.sessionLoading),
                  ],
                ),
              )
            : _error != null
            ? _buildError(l10n)
            : _buildContent(context, l10n),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    // 三类失败文案区分：完成失败（可重试）/ 评分失败 / 加载失败（缺陷三）。
    final message = _finishFailed
        ? l10n.sessionFinishFailed(_error!)
        : _rateFailed
        ? l10n.sessionRateFailed(_error!)
        : l10n.sessionLoadFailed(_error!);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_finishFailed)
              FilledButton(
                onPressed: _finishAndNavigate,
                child: Text(l10n.sessionRetry),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final word = _words[_currentWordId];
    return Column(
      children: [
        if (_feedback != null)
          Container(
            width: double.infinity,
            color: theme.colorScheme.secondaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              _feedback!,
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: word == null
                  ? Text(l10n.sessionLoading)
                  : SessionCard(
                      word: word,
                      wordbookId: widget.wordbookId,
                    ),
            ),
          ),
        ),
        RatingButtons(onRating: _rate, enabled: !_submitting && !_interrupting),
      ],
    );
  }
}
