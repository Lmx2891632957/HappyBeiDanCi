import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../domain/models/ipa_display.dart';
import '../../domain/models/word.dart';

/// 熟词快筛页（PRD F1 熟词跳过 / TECH_DOC §8.3）。
///
/// 首次进入词书（Onboarding 可选步骤）时按词书分页加载全量词条，勾选即
/// 写入 `wordbook_items.is_skipped`（不影响 user_words 与复习队列）；支持
/// 搜索（SQL LIKE 包含匹配）与「全部标记/清除」。退出时 `pop` 返回本次
/// 已标记数量供 Onboarding 展示摘要。
class SkipKnownWordsPage extends ConsumerStatefulWidget {
  const SkipKnownWordsPage({super.key, required this.wordbookId});

  final int wordbookId;

  @override
  ConsumerState<SkipKnownWordsPage> createState() =>
      _SkipKnownWordsPageState();
}

class _SkipKnownWordsPageState extends ConsumerState<SkipKnownWordsPage> {
  static const int _pageSize = 100;

  final List<Word> _words = [];
  final Set<int> _skipped = {};
  final ScrollController _scroll = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _loadingMore = false;
  bool _allLoaded = false;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final skipped = await ref
          .read(wordbookRepositoryProvider)
          .getSkippedWordIds(widget.wordbookId);
      if (!mounted) {
        return;
      }
      _skipped.addAll(skipped);
      await _loadMore();
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

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    // 初始加载（_loading=true）同样走本方法；_loading 只表示首屏转圈，
    // 不作为并发闸门（否则首屏永远卡住）。
    if (_loadingMore || _allLoaded || _searching) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final words = await ref
          .read(wordbookRepositoryProvider)
          .getAllWordsByBook(
            widget.wordbookId,
            limit: _pageSize,
            offset: _words.length,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _words.addAll(words);
        _allLoaded = words.length < _pageSize;
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
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (!mounted || !_searching) {
        return;
      }
      setState(() {
        _searching = false;
        _words.clear();
        _allLoaded = false;
        _error = null;
      });
      await _loadMore();
      return;
    }
    try {
      final results = await ref
          .read(wordbookRepositoryProvider)
          .searchWordsByBook(widget.wordbookId, trimmed, limit: 200);
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = true;
        _words
          ..clear()
          ..addAll(results);
        _allLoaded = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '$error');
    }
  }

  Future<void> _toggle(Word word, bool skipped) async {
    final previous = _skipped.contains(word.id);
    setState(() {
      if (skipped) {
        _skipped.add(word.id);
      } else {
        _skipped.remove(word.id);
      }
    });
    try {
      await ref.read(wordbookRepositoryProvider).setSkipped(
        wordbookId: widget.wordbookId,
        wordId: word.id,
        skipped: skipped,
      );
    } catch (error) {
      // 写库失败回滚本地勾选并提示（与"损坏不静默"口径一致）。
      if (!mounted) {
        return;
      }
      setState(() {
        if (previous) {
          _skipped.add(word.id);
        } else {
          _skipped.remove(word.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).skipKnownSaveFailed('$error'),
          ),
        ),
      );
    }
  }

  Future<void> _setAll(bool skipped) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(wordbookRepositoryProvider).setAllSkipped(
        widget.wordbookId,
        skipped: skipped,
      );
      // 批量更新后重新拉取标记集合（本地列表可能只含已加载分页）。
      final skippedIds = await ref
          .read(wordbookRepositoryProvider)
          .getSkippedWordIds(widget.wordbookId);
      if (!mounted) {
        return;
      }
      setState(() {
        _skipped
          ..clear()
          ..addAll(skippedIds);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.skipKnownSaveFailed('$error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.skipKnownTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_skipped.length),
            child: Text(l10n.skipKnownDone),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.skipKnownSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _setAll(true),
                icon: const Icon(Icons.done_all),
                label: Text(l10n.skipKnownSelectAll),
              ),
              TextButton.icon(
                onPressed: () => _setAll(false),
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.skipKnownClearAll),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(child: _buildList(l10n)),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.skipKnownLoadFailed(_error!)),
            TextButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = true;
                });
                _init();
              },
              child: Text(l10n.sessionRetry),
            ),
          ],
        ),
      );
    }
    if (_words.isEmpty) {
      return Center(child: Text(l10n.skipKnownEmpty));
    }
    return ListView.builder(
      controller: _scroll,
      itemCount: _words.length + (_allLoaded ? 0 : 1),
      itemBuilder: (context, index) {
        if (index >= _words.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final word = _words[index];
        // 空音标（ECDICT 兜底缺失）隐藏，避免展示 "//"（TECH_DOC §10.2）。
        final ipa = normalizeIpaForDisplay(word.phonetic);
        return CheckboxListTile(
          dense: true,
          title: Text(word.word),
          subtitle: ipa.isEmpty ? null : Text('/$ipa/'),
          value: _skipped.contains(word.id),
          onChanged: (value) => _toggle(word, value ?? false),
        );
      },
    );
  }
}
