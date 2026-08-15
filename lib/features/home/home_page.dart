import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../domain/sessions/session_snapshot.dart';
import '../learn/learn_page.dart';
import '../review/review_page.dart';

/// 今日任务页（TECH_DOC §5.1 今日页数据流）。
///
/// 展示待学新词/待复习（软上限约束）与词书剩余新词；存在未完成会话快照时
/// 提供"继续上次未完成的学习"入口（loadAll 按 updated_at 降序取最近一个）。
/// 词书选择本步先用默认词书（getWordbooks 排序后第一个，Onboarding 取舍见
/// TECH_DOC §4 补充说明 6）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayAsync = ref.watch(todayPlanProvider);
    final sessionsAsync = ref.watch(unfinishedSessionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          // 设置入口（TECH_DOC §4 补充说明 8：/settings 路由）。
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: l10n.homeLoadFailed('$error'),
          onRetry: () => ref.invalidate(todayPlanProvider),
        ),
        data: (today) => _HomeContent(
          l10n: l10n,
          today: today,
          sessionsAsync: sessionsAsync,
          onRefreshSessions: () => ref.invalidate(unfinishedSessionsProvider),
          onRetryWordbook: () => ref.invalidate(wordbookInstallProvider),
        ),
      ),
    );
  }
}

/// 词库不可用状态：安装中（准备进度）→ 完成（触发今日页重算）→ 失败可重试
/// （TECH_DOC §8.2 首装流程）。
class _WordbookUnavailable extends ConsumerStatefulWidget {
  const _WordbookUnavailable({
    required this.l10n,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  ConsumerState<_WordbookUnavailable> createState() =>
      _WordbookUnavailableState();
}

class _WordbookUnavailableState extends ConsumerState<_WordbookUnavailable> {
  @override
  void initState() {
    super.initState();
    // 首装完成后（返回值非 null）重算今日计划，词书即可用。
    ref.listen(wordbookInstallProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        ref.invalidate(todayPlanProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final install = ref.watch(wordbookInstallProvider);
    return Center(
      child: install.when(
        loading: () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.homePreparingWordbook),
          ],
        ),
        error: (error, _) => _MessageWithRetry(
          message: l10n.homeNoWordbook,
          retryLabel: l10n.homeRetry,
          onRetry: widget.onRetry,
        ),
        data: (_) => _MessageWithRetry(
          message: l10n.homeNoWordbook,
          retryLabel: l10n.homeRetry,
          onRetry: widget.onRetry,
        ),
      ),
    );
  }
}

class _MessageWithRetry extends StatelessWidget {
  const _MessageWithRetry({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
        FilledButton(onPressed: onRetry, child: Text(retryLabel)),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.l10n,
    required this.today,
    required this.sessionsAsync,
    required this.onRefreshSessions,
    required this.onRetryWordbook,
  });

  final AppLocalizations l10n;
  final TodayPlan today;
  final AsyncValue<List<SessionSnapshot>> sessionsAsync;
  final VoidCallback onRefreshSessions;
  final VoidCallback onRetryWordbook;

  @override
  Widget build(BuildContext context) {
    final book = today.wordbook;
    if (book == null) {
      return _WordbookUnavailable(l10n: l10n, onRetry: onRetryWordbook);
    }
    final plan = today.plan;
    final newCount = plan.newWordCount;
    final reviewCount = plan.reviewCount;
    final session = sessionsAsync.valueOrNull?.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.homeWordbook(book.name),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.homeNewWordsLabel,
                value: newCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.homeReviewLabel,
                value: reviewCount,
              ),
            ),
          ],
        ),
        if (plan.deferredCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.homeDeferredHint(plan.deferredCount),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 24),
        if (session != null) ...[
          _ContinueCard(
            l10n: l10n,
            session: session,
            onTap: () => _continue(context, book.id, session),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: newCount > 0
              ? () => _startLearning(context, book.id, newCount)
              : null,
          child: Text(l10n.homeStartLearning),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: reviewCount > 0
              ? () => _startReview(
                  context,
                  book.id,
                  [for (final w in plan.reviewQueue) w.wordId],
                )
              : null,
          child: Text(l10n.homeStartReview),
        ),
        if (newCount == 0 && reviewCount == 0 && session == null) ...[
          const SizedBox(height: 24),
          Icon(
            Icons.celebration,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.homeAllDone,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.homeEncouragement,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  void _startLearning(BuildContext context, int bookId, int count) {
    context.push(
      '/learn',
      extra: LearnRouteArgs(wordbookId: bookId, newWordCount: count),
    );
  }

  void _startReview(BuildContext context, int bookId, List<int> wordIds) {
    context.push(
      '/review',
      extra: ReviewRouteArgs(wordbookId: bookId, wordIds: wordIds),
    );
  }

  void _continue(BuildContext context, int bookId, SessionSnapshot session) {
    // 快照的会话类型决定进入学习页还是复习页（TECH_DOC §5.1）。
    if (session.type == SessionType.learning) {
      context.push(
        '/learn',
        extra: LearnRouteArgs(wordbookId: bookId, resumeSnapshot: session),
      );
    } else {
      context.push(
        '/review',
        extra: ReviewRouteArgs(wordbookId: bookId, resumeSnapshot: session),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              '$value',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.l10n,
    required this.session,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final SessionSnapshot session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: Text(l10n.homeContinueSession),
        subtitle: Text(
          session.type == SessionType.learning
              ? l10n.learnTitle
              : l10n.reviewTitle,
        ),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(AppLocalizations.of(context).homeRetry)),
          ],
        ),
      ),
    );
  }
}
