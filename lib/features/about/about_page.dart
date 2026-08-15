import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';

/// 关于 / 数据来源页（TECH_DOC §10.3 署名合规，PRD §7.2）。
///
/// 固定展示：考纲词表（词表口径）、ECDICT（MIT）、ipa-dict（MIT，基于
/// CMUdict）、Tatoeba（CC BY 2.0 FR，例句作者署名随词条保存）、Edge TTS；
/// 同时声明本地优先与最小化采集（T-08/§13.2）。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.aboutPrivacyNote, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(
            l10n.aboutSourcesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _SourceTile(
            title: l10n.aboutSourceGaokao,
            subtitle: l10n.aboutSourceGaokaoDesc,
          ),
          _SourceTile(
            title: l10n.aboutSourceEcdict,
            subtitle: l10n.aboutSourceEcdictDesc,
          ),
          _SourceTile(
            title: l10n.aboutSourceIpa,
            subtitle: l10n.aboutSourceIpaDesc,
          ),
          _SourceTile(
            title: l10n.aboutSourceTatoeba,
            subtitle: l10n.aboutSourceTatoebaDesc,
          ),
          _SourceTile(
            title: l10n.aboutSourceTts,
            subtitle: l10n.aboutSourceTtsDesc,
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        textColor: theme.colorScheme.onSurface,
      ),
    );
  }
}
