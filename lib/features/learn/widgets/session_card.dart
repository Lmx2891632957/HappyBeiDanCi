import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../domain/models/word.dart';

/// 会话卡片（学习/复习共用，TECH_DOC §4 补充说明 5）。
///
/// 正面：单词 + 音标 + 发音占位按钮（音频在线源未接入，置灰不阻塞核心闭环，
/// T-02）；点击翻面：常用释义（1–3 条）+ 首条例句。复习"认识/不认识快速
/// 判断"同样可翻面查看释义后作答，评分后完成页/反馈区仍展示释义。
class SessionCard extends StatefulWidget {
  const SessionCard({super.key, required this.word});

  final Word word;

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool _flipped = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _flipped = !_flipped),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _flipped ? _buildBack(context) : _buildFront(context),
        ),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final word = widget.word;
    return SizedBox(
      key: const ValueKey('front'),
      width: double.infinity,
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.word,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '/${word.phonetic}/',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // 发音占位：音频未接入前置灰（TECH_DOC §9.1 在线优先属后续迭代）。
            IconButton(
              onPressed: null,
              tooltip: l10n.audioUnavailable,
              icon: const Icon(Icons.volume_up_outlined),
            ),
            const Spacer(),
            Text(
              l10n.cardTapToFlip,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final theme = Theme.of(context);
    final word = widget.word;
    return SizedBox(
      key: const ValueKey('back'),
      width: double.infinity,
      height: 320,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final meaning in word.meanings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${meaning.pos} ${meaning.meaning}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  if (word.examples.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      word.examples.first.en,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.examples.first.zh,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.of(context).cardTapToFlip,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
