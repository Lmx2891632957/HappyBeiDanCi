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
  int? _currentWordId;
  String? _feedback;
  bool _submitting = false;
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

  Future<void> _rate(Rating rating) async {
    if (_submitting) {
      return;
    }
    _submitting = true;
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
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      // 评分异常（如数据库损坏导致取卡失败）：状态机已进入 Rating，
      // 直接重试不安全，提示用户返回（返回路径会 interrupt 保存快照）。
      setState(() => _error = '$error');
    } finally {
      _submitting = false;
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
  Future<void> _interrupt() async {
    if (_driver.phase == SessionPhase.idle ||
        _driver.phase == SessionPhase.done) {
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
    final message = _finishFailed
        ? l10n.sessionFinishFailed(_error!)
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
                  : SessionCard(word: word),
            ),
          ),
        ),
        RatingButtons(onRating: _rate, enabled: !_submitting),
      ],
    );
  }
}
