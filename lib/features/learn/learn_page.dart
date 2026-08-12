import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../domain/models/word.dart';
import '../../domain/sessions/session_snapshot.dart';
import 'session_flow.dart';

/// 学习页路由参数（home → learn；TECH_DOC §4 补充说明 4）。
///
/// 新会话：传 [wordbookId] + [newWordCount]，页面按 §8.3 学习顺序取今日新词；
/// 恢复会话：传 [resumeSnapshot]（newWordCount 忽略）。
class LearnRouteArgs {
  const LearnRouteArgs({
    required this.wordbookId,
    this.newWordCount = 0,
    this.resumeSnapshot,
  });

  final int wordbookId;
  final int newWordCount;
  final SessionSnapshot? resumeSnapshot;
}

/// 学习页：取今日新词（尚未学习的词，§8.3）后进入共用会话流程。
class LearnPage extends ConsumerStatefulWidget {
  const LearnPage({super.key, required this.args});

  final LearnRouteArgs args;

  @override
  ConsumerState<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends ConsumerState<LearnPage> {
  List<Word>? _words;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.args.resumeSnapshot != null) {
      // 恢复路径：队列来自快照，词条由 SessionFlow 按 ID 批量取（§8.3）。
      setState(() => _words = const []);
      return;
    }
    try {
      final words = await ref.read(wordbookRepositoryProvider).getWordsByBook(
        widget.args.wordbookId,
        limit: widget.args.newWordCount,
      );
      if (!mounted) {
        return;
      }
      setState(() => _words = words);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.learnTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.sessionLoadFailed(_error!)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: Text(l10n.sessionRetry)),
              ],
            ),
          ),
        ),
      );
    }
    if (_words == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.learnTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return SessionFlow(
      type: SessionType.learning,
      wordbookId: widget.args.wordbookId,
      initialWords: _words,
      resumeSnapshot: widget.args.resumeSnapshot,
    );
  }
}
