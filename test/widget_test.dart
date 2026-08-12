import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/app/app.dart';
import 'package:happy_bei_dan_ci/features/home/home_page.dart';

void main() {
  testWidgets('应用骨架可装配并渲染首页占位', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    // flutter test 默认 locale 为 en_US，断言英文文案；中文文案断言不依赖环境。
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Wo Ai Bei Dan Ci'), findsOneWidget);
  });
}
