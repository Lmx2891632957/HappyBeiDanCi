import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../domain/scheduling/fsrs_scheduler.dart';

/// 三键反馈（学习/复习共用，TECH_DOC §7.3 评分映射）：
/// 不认识 → Again、模糊 → Hard、认识 → Good。
///
/// 学习与复习共用同一交互（§4 补充说明 5）；复习题型在本步仅为
/// "认识/不认识快速判断"卡片，评分映射不变（§5.3 取舍）。
class RatingButtons extends StatelessWidget {
  const RatingButtons({
    super.key,
    required this.onRating,
    this.enabled = true,
  });

  final ValueChanged<Rating> onRating;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: enabled ? () => onRating(Rating.again) : null,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
              ),
              child: Text(l10n.rateAgain),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonal(
              onPressed: enabled ? () => onRating(Rating.hard) : null,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.tertiaryContainer,
                foregroundColor: scheme.onTertiaryContainer,
              ),
              child: Text(l10n.rateHard),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: enabled ? () => onRating(Rating.good) : null,
              child: Text(l10n.rateGood),
            ),
          ),
        ],
      ),
    );
  }
}
