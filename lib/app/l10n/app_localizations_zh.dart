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
  String get onboardingSkipKnownWords => '标记已掌握词（可选）';

  @override
  String onboardingSkipCount(int count) {
    return '已标记 $count 个词';
  }

  @override
  String get skipKnownTitle => '标记已掌握词';

  @override
  String get skipKnownSearchHint => '搜索单词';

  @override
  String get skipKnownSelectAll => '全部标记';

  @override
  String get skipKnownClearAll => '全部清除';

  @override
  String get skipKnownDone => '完成';

  @override
  String skipKnownSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String skipKnownLoadFailed(String error) {
    return '加载单词失败：$error';
  }

  @override
  String get skipKnownEmpty => '未找到单词';

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
  String get homePreparingWordbook => '正在准备词库…';

  @override
  String homeWordbook(String name) {
    return '词书：$name';
  }

  @override
  String get homeNewWordsLabel => '待学新词';

  @override
  String get homeReviewLabel => '待复习';

  @override
  String homeLearnedToday(int count) {
    return '今日已学单词：$count个';
  }

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
  String get settingsTitle => '设置';

  @override
  String get settingsGoalSection => '学习目标';

  @override
  String get settingsDailyGoal => '每日新词数';

  @override
  String get settingsReviewCap => '每日复习上限';

  @override
  String get settingsReviewCapHint => '超出上限的逾期复习自动顺延到次日';

  @override
  String get settingsReviewCapOff => '关闭';

  @override
  String get settingsPronunciationSection => '音频';

  @override
  String get settingsPronunciation => '单词发音';

  @override
  String get settingsCellularDownload => '蜂窝网络下载发音包';

  @override
  String get settingsCellularDownloadHint => '默认关闭以节省流量，Wi-Fi 下自动下载';

  @override
  String get settingsReminderSection => '每日提醒';

  @override
  String get settingsReminder => '开启每日提醒';

  @override
  String get settingsReminderTime => '提醒时间';

  @override
  String get settingsAppearanceSection => '外观';

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get settingsDarkSystem => '跟随系统';

  @override
  String get settingsDarkLight => '浅色';

  @override
  String get settingsDarkDark => '深色';

  @override
  String get settingsDataSection => '数据';

  @override
  String get settingsExportCsv => '导出复习记录与学习进度（CSV）';

  @override
  String get settingsExportJson => '导出复习记录与学习进度（JSON）';

  @override
  String get settingsExportSubject => '我的背单词数据';

  @override
  String settingsExportSuccess(int count) {
    return '已导出 $count 个文件';
  }

  @override
  String settingsExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String settingsSaveFailed(String error) {
    return '保存设置失败：$error';
  }

  @override
  String get settingsAbout => '关于与数据来源';

  @override
  String get settingsNotificationPermissionDenied =>
      '通知权限已关闭，请在系统设置中开启以接收每日提醒。';

  @override
  String get settingsOpenSystemSettings => '去设置';

  @override
  String get reminderNotificationTitle => '该复习啦';

  @override
  String get reminderNotificationBody => '完成今天的生词和复习吧。';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutPrivacyNote => '本应用是免费学习工具，学习数据仅保存在本机，不上传任何个人数据。';

  @override
  String get aboutSourcesTitle => '数据来源';

  @override
  String get aboutSourceGaokao => '教育部《高考英语考试大纲》词汇表';

  @override
  String get aboutSourceGaokaoDesc => '词表口径；无官方机器可读文件，以 ECDICT gk 标签为种子';

  @override
  String get aboutSourceEcdict => 'ECDICT（MIT 协议）';

  @override
  String get aboutSourceEcdictDesc => '释义、词性、兜底音标、考频代理';

  @override
  String get aboutSourceIpa => 'ipa-dict en_US（MIT，基于 CMUdict）';

  @override
  String get aboutSourceIpaDesc => '美式 IPA 音标（主源）';

  @override
  String get aboutSourceTatoeba => 'Tatoeba 英语例句库（CC BY 2.0 FR）';

  @override
  String get aboutSourceTatoebaDesc => '例句随词条保存作者署名，满足署名要求';

  @override
  String get aboutSourceTts => 'Microsoft Edge TTS（en-US-AriaNeural）';

  @override
  String get aboutSourceTtsDesc => '美音发音批量生成';

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
