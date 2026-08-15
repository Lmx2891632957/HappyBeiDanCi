import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../domain/models/ipa_display.dart';
import '../../../domain/models/word.dart';

/// 会话卡片（学习/复习共用，TECH_DOC §4 补充说明 5）。
///
/// 正面：单词 + 音标 + 发音按钮（F5 在线优先 + 离线包，TECH_DOC §9.1）；
/// 点击翻面：常用释义（1–3 条）+ 例句。复习"认识/不认识快速判断"同样
/// 可翻面查看释义后作答，评分后完成页/反馈区仍展示释义。
///
/// 布局口径（2026-08-16 优化）：
/// - 卡片高度自适应可用空间（上限 [maxHeight]），提高屏幕利用率；
/// - 反面例句固定在释义区下方、**始终可见**：释义较多时仅释义区内部滚动，
///   例句不再被挤出首屏（避免误以为单词没有例句）；例句过长时可点按
///   展开/收起，展开超出部分在例句区内滚动，不撑破卡片。
class SessionCard extends ConsumerStatefulWidget {
  const SessionCard({super.key, required this.word, required this.wordbookId});

  /// 卡片最大高度：可用空间超过时封顶，保持"卡片"观感而非整屏面板。
  static const double maxHeight = 520;

  /// 无界约束（极端场景）下的回退高度。
  static const double fallbackHeight = 320;

  final Word word;
  final int wordbookId;

  @override
  ConsumerState<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<SessionCard> {
  bool _flipped = false;
  bool _exampleExpanded = false;

  @override
  void didUpdateWidget(SessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 换词后重置卡片状态：回到正面并收起例句，避免上一张卡的翻面/展开态
    // 带到下一张卡（每张新词卡应从"先看词"开始）。
    if (oldWidget.word.id != widget.word.id) {
      _flipped = false;
      _exampleExpanded = false;
    }
  }

  Future<void> _playPronunciation() {
    // 在线优先 + 离线包兜底：播放失败由服务内部静默记录，不打断学习节奏
    // （TECH_DOC §9.1）；播放不阻塞 UI（unawaited）。
    return ref
        .read(audioPlaybackServiceProvider)
        .play(
          wordbookId: widget.wordbookId,
          audioKey: widget.word.audioKey,
          audioUrl: widget.word.audioUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.hasBoundedHeight
              ? math.min(constraints.maxHeight, SessionCard.maxHeight)
              : SessionCard.fallbackHeight;
          return InkWell(
            onTap: () => setState(() => _flipped = !_flipped),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  _flipped ? _buildBack(context, height) : _buildFront(context, height),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context, double height) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final word = widget.word;
    // 空音标（ECDICT 兜底缺失）不展示，避免出现 "//"（TECH_DOC §10.2）。
    final ipa = normalizeIpaForDisplay(word.phonetic);
    return SizedBox(
      key: const ValueKey('front'),
      width: double.infinity,
      height: height,
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
            if (ipa.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '/$ipa/',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 发音按钮：发音开关关闭或无可用播放源时为 no-op（§9.1）。
            IconButton(
              onPressed: () => unawaited(_playPronunciation()),
              tooltip: l10n.audioPlay,
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

  Widget _buildBack(BuildContext context, double height) {
    final theme = Theme.of(context);
    final word = widget.word;
    return SizedBox(
      key: const ValueKey('back'),
      width: double.infinity,
      height: height,
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
            // 释义区：内容超高时仅此区内部滚动；例句固定在下方始终可见。
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
                ],
              ),
            ),
            if (word.examples.isNotEmpty) ...[
              const Divider(height: 24),
              _buildExampleSection(context, height),
            ],
            const SizedBox(height: 12),
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

  /// 例句固定展示区：折叠态最多 2 行英文 + 1 行中文（省略号截断），
  /// 点按展开全文；展开态超出部分在例句区内滚动，不撑破卡片。
  Widget _buildExampleSection(BuildContext context, double height) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: _exampleExpanded ? l10n.cardExampleCollapse : l10n.cardExampleExpand,
      child: InkWell(
        onTap: () => setState(() => _exampleExpanded = !_exampleExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    l10n.cardExampleLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _exampleExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (_exampleExpanded)
                // 展开态：例句可能很长，限制在卡片高度的一部分内滚动，
                // 避免与释义区争夺空间时把卡片撑破（大字号/超长句防御）。
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height * 0.35),
                  child: SingleChildScrollView(
                    child: _buildExampleTexts(theme, expanded: true),
                  ),
                )
              else
                _buildExampleTexts(theme, expanded: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleTexts(ThemeData theme, {required bool expanded}) {
    final example = widget.word.examples.first;
    final enStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
    );
    final zhStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          example.en,
          style: enStyle,
          // 折叠态截断到 2 行：既保证例句可见，又不占用过多释义空间。
          maxLines: expanded ? null : 2,
          overflow: expanded ? null : TextOverflow.ellipsis,
        ),
        if (example.zh != null) ...[
          const SizedBox(height: 4),
          Text(
            example.zh!,
            style: zhStyle,
            maxLines: expanded ? null : 1,
            overflow: expanded ? null : TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
