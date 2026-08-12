import 'package:flutter_test/flutter_test.dart';
import 'package:happy_bei_dan_ci/core/constants.dart';

void main() {
  group('AppConstants 与 TECH_DOC §18 默认值一致', () {
    test('每日目标与复习软上限', () {
      expect(AppConstants.defaultDailyNewWords, 20);
      expect(AppConstants.defaultReviewCap, 300);
    });

    test('FSRS 参数与会话约束', () {
      expect(AppConstants.defaultDesiredRetention, closeTo(0.9, 1e-9));
      expect(AppConstants.learningStepsMinutes, [10]);
      expect(AppConstants.relearningStepsMinutes, [10]);
      expect(AppConstants.maxRequeuePerSession, 2);
    });

    test('提醒与时区', () {
      expect(AppConstants.defaultReminderTime, '20:00');
      expect(AppConstants.defaultTimezone, 'Asia/Shanghai');
    });
  });
}
