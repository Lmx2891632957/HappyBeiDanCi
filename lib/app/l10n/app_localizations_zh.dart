// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '我爱背单词';

  @override
  String get onboardingTitle => '开始使用';

  @override
  String get onboardingWordbookLabel => '选择词书';

  @override
  String get onboardingDailyGoalLabel => '每日新词目标（词/天）';

  @override
  String get onboardingStart => '开始';

  @override
  String get onboardingNoWordbook => '暂无可用词书（词库包未安装）';

  @override
  String onboardingLoadFailed(String error) {
    return '初始化失败：$error';
  }

  @override
  String onboardingSaveFailed(String error) {
    return '保存设置失败：$error';
  }

  @override
  String get homeSkeletonReady => '工程骨架已就绪。';

  @override
  String get homeTitle => '今日任务';

  @override
  String get homeLoading => '加载中…';

  @override
  String homeLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get homeRetry => '重试';

  @override
  String get homeNoWordbook => '暂无可用词书（词库包未安装）';

  @override
  String homeWordbook(String name) {
    return '词书：$name';
  }

  @override
  String get homeNewWordsLabel => '待学新词';

  @override
  String get homeReviewLabel => '待复习';

  @override
  String homeDeferredHint(int count) {
    return '另有 $count 词顺延至明日';
  }

  @override
  String get homeStartLearning => '开始学习';

  @override
  String get homeStartReview => '开始复习';

  @override
  String get homeContinueSession => '继续上次未完成的学习';

  @override
  String get homeAllDone => '今日任务已完成';

  @override
  String get homeEncouragement => '坚持就是胜利，明天见！';

  @override
  String get learnTitle => '学习新词';

  @override
  String get reviewTitle => '复习';

  @override
  String get sessionLoading => '准备卡片…';

  @override
  String sessionLoadFailed(String error) {
    return '会话加载失败：$error';
  }

  @override
  String sessionFinishFailed(String error) {
    return '完成会话失败：$error';
  }

  @override
  String sessionRateFailed(String error) {
    return '评分失败：$error';
  }

  @override
  String get sessionRetry => '重试';

  @override
  String get cardTapToFlip => '点击卡片查看释义';

  @override
  String get rateAgain => '不认识';

  @override
  String get rateHard => '模糊';

  @override
  String get rateGood => '认识';

  @override
  String feedbackAgain(String word) {
    return '不认识：$word（稍后再次出现）';
  }

  @override
  String feedbackHard(String word) {
    return '模糊：$word';
  }

  @override
  String feedbackGood(String word) {
    return '认识：$word';
  }

  @override
  String get audioUnavailable => '发音暂不可用';

  @override
  String get audioPlay => '播放发音';

  @override
  String get audioDownloadNotificationTitle => '正在下载发音包';

  @override
  String get audioDownloadNotificationText => '正在下载单词发音，完成后可离线播放';

  @override
  String get audioDownloadNotificationChannelName => '发音包下载';

  @override
  String get resultsTitle => '今日成果';

  @override
  String get resultsCheckinSuccess => '打卡成功！';

  @override
  String resultsSummary(int newCount, int reviewCount) {
    return '今日已学新词 $newCount · 复习 $reviewCount';
  }

  @override
  String get resultsProgress => '今日进度';

  @override
  String resultsRemainingNew(int count) {
    return '还差 $count 个新词';
  }

  @override
  String resultsRemainingReview(int count) {
    return '还差 $count 个复习';
  }

  @override
  String resultsTomorrow(int count) {
    return '明日预告：预计新词 $count 个';
  }

  @override
  String get resultsEncouragement => '坚持就是胜利，明天见！';

  @override
  String get resultsBackHome => '回到首页';

  @override
  String resultsLoadFailed(String error) {
    return '加载今日进度失败：$error';
  }
}
