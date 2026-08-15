import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/services/data_export_formatter.dart';

/// 设置页（PRD F7 / TECH_DOC §4 补充说明 9，M1 范围）。
///
/// 覆盖：每日目标、复习软上限、发音开关、蜂窝下载、每日提醒（开关+时间）、
/// 界面语言、深色模式、数据导出（CSV/JSON）与「关于/数据来源」入口。
/// 所有变更经 `SettingsRepository.save` 全量写入（§8.1）并
/// `invalidate(appSettingsProvider)` 即时生效；提醒变更同步
/// `ReminderScheduler` 重排（§11.1），Android 13+ 权限被拒时给出系统设置引导。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  AppSettings? _settings;
  bool _reminderPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    if (!mounted) {
      return;
    }
    setState(() => _settings = settings);
  }

  Future<void> _save(AppSettings next) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _settings = next);
    try {
      await ref.read(settingsRepositoryProvider).save(next);
      ref.invalidate(appSettingsProvider);
      await _syncReminder(next);
    } catch (error) {
      AppLogger.warning('设置保存失败：$error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsSaveFailed('$error'))));
    }
  }

  /// 提醒开关/时间变更后的排程同步（TECH_DOC §11.1）：关闭 → 取消任务；
  /// 开启 → 权限检测/申请 → 按 settings.timezone 重新 zonedSchedule。
  Future<void> _syncReminder(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!settings.reminderEnabled) {
      await scheduler.cancel();
      return;
    }
    final granted = await scheduler.areNotificationsEnabled();
    if (granted == false) {
      final requested = await scheduler.requestNotificationsPermission();
      if (requested != true) {
        if (!mounted) {
          return;
        }
        // 用户拒绝：展示系统设置引导，不反复弹窗（§11.1）。
        setState(() => _reminderPermissionDenied = true);
        return;
      }
    }
    final parts = settings.reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;
    await scheduler.scheduleDaily(
      timezoneName: settings.timezone,
      now: DateTime.now(),
      hour: hour,
      minute: minute,
      title: l10n.reminderNotificationTitle,
      body: l10n.reminderNotificationBody,
    );
  }

  Future<void> _pickReminderTime(AppSettings settings) async {
    final parts = settings.reminderTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: parts.length > 1 ? int.parse(parts[1]) : 0,
      ),
    );
    if (picked == null) {
      return;
    }
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    await _save(AppSettings(
      dailyNewWords: settings.dailyNewWords,
      reviewCap: settings.reviewCap,
      reminderEnabled: settings.reminderEnabled,
      reminderTime: time,
      examDate: settings.examDate,
      timezone: settings.timezone,
      onboardingDone: settings.onboardingDone,
      wordbookVersion: settings.wordbookVersion,
      pronunciationEnabled: settings.pronunciationEnabled,
      audioDownloadOnCellular: settings.audioDownloadOnCellular,
      language: settings.language,
      themeMode: settings.themeMode,
    ));
  }

  Future<void> _export(ExportFormat format) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(dataExporterProvider).export(
        format: format,
        shareSubject: l10n.settingsExportSubject,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportSuccess(result.filePaths.length))),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExportFailed('$error'))),
      );
    }
  }

  Future<void> _openNotificationSettings() async {
    await ref.read(reminderSchedulerProvider).openNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_reminderPermissionDenied)
                  _PermissionBanner(
                    message: l10n.settingsNotificationPermissionDenied,
                    actionLabel: l10n.settingsOpenSystemSettings,
                    onAction: _openNotificationSettings,
                  ),
                _SectionLabel(l10n.settingsGoalSection),
                _goalSection(context, l10n, settings),
                const Divider(),
                _SectionLabel(l10n.settingsPronunciationSection),
                SwitchListTile(
                  title: Text(l10n.settingsPronunciation),
                  value: settings.pronunciationEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(pronunciationEnabled: value),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.settingsCellularDownload),
                  subtitle: Text(l10n.settingsCellularDownloadHint),
                  value: settings.audioDownloadOnCellular,
                  onChanged: (value) => _save(
                    settings.copyWith(audioDownloadOnCellular: value),
                  ),
                ),
                const Divider(),
                _SectionLabel(l10n.settingsReminderSection),
                SwitchListTile(
                  title: Text(l10n.settingsReminder),
                  value: settings.reminderEnabled,
                  onChanged: (value) => _save(
                    settings.copyWith(reminderEnabled: value),
                  ),
                ),
                ListTile(
                  enabled: settings.reminderEnabled,
                  title: Text(l10n.settingsReminderTime),
                  trailing: Text(
                    settings.reminderTime,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => _pickReminderTime(settings),
                ),
                const Divider(),
                _SectionLabel(l10n.settingsAppearanceSection),
                ListTile(
                  title: Text(l10n.settingsLanguage),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: '',
                        label: Text(l10n.settingsLanguageSystem),
                      ),
                      const ButtonSegment(value: 'zh', label: Text('中文')),
                      const ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {settings.language},
                    onSelectionChanged: (selection) => _save(
                      settings.copyWith(language: selection.first),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(l10n.settingsDarkMode),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'system',
                        label: Text(l10n.settingsDarkSystem),
                      ),
                      ButtonSegment(
                        value: 'light',
                        label: Text(l10n.settingsDarkLight),
                      ),
                      ButtonSegment(
                        value: 'dark',
                        label: Text(l10n.settingsDarkDark),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) => _save(
                      settings.copyWith(themeMode: selection.first),
                    ),
                  ),
                ),
                const Divider(),
                _SectionLabel(l10n.settingsDataSection),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: Text(l10n.settingsExportCsv),
                  onTap: () => _export(ExportFormat.csv),
                ),
                ListTile(
                  leading: const Icon(Icons.data_object),
                  title: Text(l10n.settingsExportJson),
                  onTap: () => _export(ExportFormat.json),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.settingsAbout),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
    );
  }

  Widget _goalSection(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(l10n.settingsDailyGoal),
          trailing: SegmentedButton<int>(
            segments: [
              for (final goal in AppConstants.dailyGoalOptions)
                ButtonSegment(value: goal, label: Text('$goal')),
            ],
            selected: {settings.dailyNewWords},
            onSelectionChanged: (selection) => _save(
              settings.copyWith(dailyNewWords: selection.first),
            ),
          ),
        ),
        ListTile(
          title: Text(l10n.settingsReviewCap),
          subtitle: Text(l10n.settingsReviewCapHint),
          trailing: DropdownButton<int?>(
            value: settings.reviewCap,
            underline: const SizedBox.shrink(),
            items: [
              for (final cap in const [100, 200, 300, 500])
                DropdownMenuItem(value: cap, child: Text('$cap')),
              DropdownMenuItem(
                value: null,
                child: Text(l10n.settingsReviewCapOff),
              ),
            ],
            onChanged: (value) => _save(settings.copyWith(reviewCap: value)),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.notifications_off, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
