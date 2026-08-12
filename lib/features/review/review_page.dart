import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../domain/models/word.dart';
import '../../domain/sessions/session_snapshot.dart';
import '../learn/session_flow.dart';

/// 复习页路由参数（home → review；TECH_DOC §4 补充说明 4）。
///
/// 新会话：传 [wordbookId] + [wordIds]（今日计划内到期队列，已排序截断）；
/// 恢复会话：传 [resumeSnapshot]（wordIds 忽略）。
class ReviewRouteArgs {
  const ReviewRouteArgs({
    required this.wordbookId,
    this.wordIds = const [],
    this.resumeSnapshot,
  });

  final int wordbookId;
  final List<int> wordIds;
  final SessionSnapshot? resumeSnapshot;
}

/// 复习页：取到期词条后进入共用会话流程（题型本步为"认识/不认识快速判断"，
/// 四选一/拼写等题型分配属后续迭代，TECH_DOC §5.3 取舍）。
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key, required this.args});

  final ReviewRouteArgs args;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
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
      final words = await ref
          .read(wordbookRepositoryProvider)
          .getWordsByIds(widget.args.wordIds);
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
        appBar: AppBar(title: Text(l10n.reviewTitle)),
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
        appBar: AppBar(title: Text(l10n.reviewTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return SessionFlow(
      type: SessionType.review,
      wordbookId: widget.args.wordbookId,
      initialWords: _words,
      resumeSnapshot: widget.args.resumeSnapshot,
    );
  }
}
