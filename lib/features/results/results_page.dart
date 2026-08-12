import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/time_utils.dart';
import '../../domain/models/daily_plan.dart';
import '../../domain/models/daily_stats.dart';
import '../../domain/services/daily_checkin_calculator.dart';

/// 任务完成页（PRD §5 / TECH_DOC §5.5）。
///
/// 会话 finish 后进入：读取当日 daily_stats（含本场会话累加）与重算的今日计划，
/// 按 `DailyCheckinCalculator` 判定整日任务是否完成；满足时置
/// `daily_stats.completed = 1`（打卡）并展示明日预告与鼓励文案，不满足时
/// 展示进度差并引导回到今日页继续。
class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({super.key});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  bool _loading = true;
  String? _error;
  DailyStats? _stats;
  DailyPlan? _plan;
  int? _tomorrowNewWords;
  bool _complete = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // 重算今日计划：学习/复习完成后到期队列与剩余新词已变化，重算结果
      // 即"今日计划内队列是否已清空"的当前事实（TECH_DOC §5.5 口径说明）。
      final today = await ref.read(todayPlanProvider.future);
      final day = TimeUtils.localDayKey(DateTime.now());
      var stats = await ref.read(statsRepositoryProvider).getByDay(day);
      final complete = DailyCheckinCalculator.isTodayComplete(
        plan: today.plan,
        stats: stats ?? DailyStats(day: day),
      );

      // 打卡置位由任务完成页负责（§5.4 驱动契约：驱动不置位）。
      if (complete && (stats?.completed ?? 0) == 0) {
        final updated = DailyStats(
          day: day,
          newCount: stats?.newCount ?? 0,
          reviewCount: stats?.reviewCount ?? 0,
          correctCount: stats?.correctCount ?? 0,
          completed: 1,
        );
        await ref.read(statsRepositoryProvider).upsert(updated);
        stats = updated;
      }

      // 明日预告：预计新词 = min(每日目标, 今日结束后剩余新词)。
      final tomorrow = math.min(
        today.settings.dailyNewWords,
        today.remainingNewWords,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _stats = stats;
        _plan = today.plan;
        _complete = complete;
        _tomorrowNewWords = tomorrow;
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.resultsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(context, l10n)
          : _buildContent(context, l10n),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.resultsLoadFailed(_error!), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: Text(l10n.homeRetry)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final stats = _stats!;
    final plan = _plan!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_complete) ...[
          Icon(
            Icons.check_circle,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.resultsCheckinSuccess,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ] else ...[
          Icon(
            Icons.trending_up,
            size: 72,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.resultsProgress,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.resultsSummary(stats.newCount, stats.reviewCount),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        if (_complete) ...[
          if (_tomorrowNewWords != null)
            Text(
              l10n.resultsTomorrow(_tomorrowNewWords!),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          Text(
            l10n.resultsEncouragement,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ] else ...[
          Text(
            l10n.resultsRemainingNew(
              math.max(0, plan.newWordCount - stats.newCount),
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.resultsRemainingReview(
              math.max(0, plan.reviewCount - stats.reviewCount),
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.go('/'),
          child: Text(l10n.resultsBackHome),
        ),
      ],
    );
  }
}
