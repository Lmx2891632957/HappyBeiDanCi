import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/wordbook.dart';

/// 首次启动引导页（PRD §3.1 设计原则 5「默认启动即用」/ TECH_DOC §5.1）。
///
/// 单页三步：选词书（默认选中第一个，M1 单词书口径见 §4 补充说明 7）→
/// 设每日目标（10/20/30/50，默认 20，PRD F2 / §18）→ 开始。完成时
/// `SettingsRepository.save` 一次事务写入每日目标与 `onboarding_done=true`
/// （原子、幂等），随后直达今日任务页；熟词跳过本步未实现（§4 补充说明 7）。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  List<Wordbook>? _wordbooks;
  String? _loadError;
  int? _selectedBookId;
  int _dailyGoal = AppConstants.defaultDailyNewWords;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final wordbooks = await ref
          .read(wordbookRepositoryProvider)
          .getWordbooks();
      if (!mounted) {
        return;
      }
      setState(() {
        _wordbooks = wordbooks;
        // 默认选中第一个（M1 单词书场景与今日页“默认第一个”等价，§4 补充说明 7）。
        _selectedBookId = wordbooks.isEmpty ? null : wordbooks.first.id;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = '$error');
    }
  }

  Future<void> _start() async {
    final bookId = _selectedBookId;
    if (bookId == null || _saving) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final settings = await ref.read(settingsRepositoryProvider).load();
      // 保留既有设置（首启时均为默认值），仅更新每日目标并置首启标记；
      // save 为同事务全量写入，中断/重复进入不会留下“目标已改但标记未置”的状态。
      await ref
          .read(settingsRepositoryProvider)
          .save(
            AppSettings(
              dailyNewWords: _dailyGoal,
              reviewCap: settings.reviewCap,
              reminderEnabled: settings.reminderEnabled,
              reminderTime: settings.reminderTime,
              examDate: settings.examDate,
              timezone: settings.timezone,
              onboardingDone: true,
            ),
          );
      if (!mounted) {
        return;
      }
      // F5：首启完成即开始后台下载当前词书发音离线包（Wi-Fi 策略见设置，
      // §9.2）；调度失败不影响学习（在线兜底，T-02）。
      unawaited(
        _scheduleAudioPack(bookId, settings.wordbookVersion),
      );
      // go 替换路由栈：返回键不回到引导页；今日页已可用，无需改动其逻辑。
      context.go('/');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).onboardingSaveFailed('$error'),
          ),
        ),
      );
    }
  }

  Future<void> _scheduleAudioPack(int bookId, String? version) async {
    if (version == null || version.isEmpty) {
      return;
    }
    try {
      final l10n = AppLocalizations.of(context);
      await ref.read(audioPackDownloadSchedulerProvider).scheduleIfNeeded(
        wordbookId: bookId,
        version: version,
        notificationTitle: l10n.audioDownloadNotificationTitle,
        notificationText: l10n.audioDownloadNotificationText,
        notificationChannelName: l10n.audioDownloadNotificationChannelName,
      );
    } catch (error) {
      AppLogger.warning('首启后音频包下载调度失败：$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wordbooks = _wordbooks;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: _loadError != null
          ? _ErrorView(
              message: l10n.onboardingLoadFailed(_loadError!),
              onRetry: _load,
            )
          : wordbooks == null
          ? const Center(child: CircularProgressIndicator())
          : wordbooks.isEmpty
          ? Center(child: Text(l10n.onboardingNoWordbook))
          : _buildForm(context, l10n, wordbooks),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    List<Wordbook> wordbooks,
  ) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l10n.onboardingWordbookLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final book in wordbooks) ...[
          _WordbookTile(
            book: book,
            selected: book.id == _selectedBookId,
            onTap: () => setState(() => _selectedBookId = book.id),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        Text(l10n.onboardingDailyGoalLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final goal in AppConstants.dailyGoalOptions)
              ButtonSegment(value: goal, label: Text('$goal')),
          ],
          selected: {_dailyGoal},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              setState(() => _dailyGoal = selection.first);
            }
          },
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _saving ? null : _start,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.onboardingStart),
        ),
      ],
    );
  }
}

/// 词书选择项：M1 单词书默认选中第一个；多词书选择持久化留待后续迭代
/// （TECH_DOC §4 补充说明 7）。
class _WordbookTile extends StatelessWidget {
  const _WordbookTile({
    required this.book,
    required this.selected,
    required this.onTap,
  });

  final Wordbook book;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: ListTile(
        leading: Icon(
          selected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: selected ? theme.colorScheme.primary : null,
        ),
        title: Text(book.name),
        subtitle: Text('${book.totalCount}'),
        onTap: onTap,
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.homeRetry)),
          ],
        ),
      ),
    );
  }
}
