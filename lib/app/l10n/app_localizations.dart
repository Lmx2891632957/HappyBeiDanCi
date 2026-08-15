import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用显示名称（英文界面文案）
  ///
  /// In en, this message translates to:
  /// **'Wo Ai Bei Dan Ci'**
  String get appTitle;

  /// 首次启动引导页标题
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingTitle;

  /// 首次启动引导页：选择词书
  ///
  /// In en, this message translates to:
  /// **'Choose your wordbook'**
  String get onboardingWordbookLabel;

  /// 首次启动引导页：每日新词目标
  ///
  /// In en, this message translates to:
  /// **'Daily new words goal (words/day)'**
  String get onboardingDailyGoalLabel;

  /// 首次启动引导页：开始按钮
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// 词库包未安装时的引导页提示
  ///
  /// In en, this message translates to:
  /// **'No wordbook available (content pack not installed)'**
  String get onboardingNoWordbook;

  /// 首次启动初始化失败
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize: {error}'**
  String onboardingLoadFailed(String error);

  /// 引导页保存设置失败
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings: {error}'**
  String onboardingSaveFailed(String error);

  /// 首页占位提示：工程骨架已就绪
  ///
  /// In en, this message translates to:
  /// **'Project skeleton is ready.'**
  String get homeSkeletonReady;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTitle;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get homeLoading;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String homeLoadFailed(String error);

  /// No description provided for @homeRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeRetry;

  /// No description provided for @homeNoWordbook.
  ///
  /// In en, this message translates to:
  /// **'No wordbook available (content pack not installed)'**
  String get homeNoWordbook;

  /// No description provided for @homeWordbook.
  ///
  /// In en, this message translates to:
  /// **'Wordbook: {name}'**
  String homeWordbook(String name);

  /// No description provided for @homeNewWordsLabel.
  ///
  /// In en, this message translates to:
  /// **'New words'**
  String get homeNewWordsLabel;

  /// No description provided for @homeReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Due reviews'**
  String get homeReviewLabel;

  /// No description provided for @homeDeferredHint.
  ///
  /// In en, this message translates to:
  /// **'{count} more words deferred to tomorrow'**
  String homeDeferredHint(int count);

  /// No description provided for @homeStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get homeStartLearning;

  /// No description provided for @homeStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get homeStartReview;

  /// No description provided for @homeContinueSession.
  ///
  /// In en, this message translates to:
  /// **'Continue unfinished session'**
  String get homeContinueSession;

  /// No description provided for @homeAllDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks completed'**
  String get homeAllDone;

  /// No description provided for @homeEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Keep going — see you tomorrow!'**
  String get homeEncouragement;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn new words'**
  String get learnTitle;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @sessionLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing cards…'**
  String get sessionLoading;

  /// No description provided for @sessionLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load session: {error}'**
  String sessionLoadFailed(String error);

  /// No description provided for @sessionFinishFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to finish session: {error}'**
  String sessionFinishFailed(String error);

  /// No description provided for @sessionRateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to rate: {error}'**
  String sessionRateFailed(String error);

  /// No description provided for @sessionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get sessionRetry;

  /// No description provided for @cardTapToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to see the meaning'**
  String get cardTapToFlip;

  /// No description provided for @rateAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get rateAgain;

  /// No description provided for @rateHard.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get rateHard;

  /// No description provided for @rateGood.
  ///
  /// In en, this message translates to:
  /// **'Know it'**
  String get rateGood;

  /// No description provided for @feedbackAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know: {word} (will appear again)'**
  String feedbackAgain(String word);

  /// No description provided for @feedbackHard.
  ///
  /// In en, this message translates to:
  /// **'Not sure: {word}'**
  String feedbackHard(String word);

  /// No description provided for @feedbackGood.
  ///
  /// In en, this message translates to:
  /// **'Know it: {word}'**
  String feedbackGood(String word);

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio not available yet'**
  String get audioUnavailable;

  /// 卡片发音按钮提示
  ///
  /// In en, this message translates to:
  /// **'Play pronunciation'**
  String get audioPlay;

  /// 离线发音包前台服务通知标题
  ///
  /// In en, this message translates to:
  /// **'Downloading pronunciation pack'**
  String get audioDownloadNotificationTitle;

  /// 离线发音包前台服务通知正文
  ///
  /// In en, this message translates to:
  /// **'Downloading audio; offline playback available when finished'**
  String get audioDownloadNotificationText;

  /// 离线发音包前台服务通知频道名
  ///
  /// In en, this message translates to:
  /// **'Pronunciation pack download'**
  String get audioDownloadNotificationChannelName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGoalSection.
  ///
  /// In en, this message translates to:
  /// **'Study goal'**
  String get settingsGoalSection;

  /// No description provided for @settingsDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily new words'**
  String get settingsDailyGoal;

  /// No description provided for @settingsReviewCap.
  ///
  /// In en, this message translates to:
  /// **'Daily review cap'**
  String get settingsReviewCap;

  /// No description provided for @settingsReviewCapHint.
  ///
  /// In en, this message translates to:
  /// **'Overdue reviews above the cap are deferred to tomorrow'**
  String get settingsReviewCapHint;

  /// No description provided for @settingsReviewCapOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsReviewCapOff;

  /// No description provided for @settingsPronunciationSection.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsPronunciationSection;

  /// No description provided for @settingsPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation'**
  String get settingsPronunciation;

  /// No description provided for @settingsCellularDownload.
  ///
  /// In en, this message translates to:
  /// **'Download audio on mobile data'**
  String get settingsCellularDownload;

  /// No description provided for @settingsCellularDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Off by default to save data; downloads start on Wi-Fi'**
  String get settingsCellularDownloadHint;

  /// No description provided for @settingsReminderSection.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsReminderSection;

  /// No description provided for @settingsReminder.
  ///
  /// In en, this message translates to:
  /// **'Enable daily reminder'**
  String get settingsReminder;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsReminderTime;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsDarkSystem;

  /// No description provided for @settingsDarkLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsDarkLight;

  /// No description provided for @settingsDarkDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDarkDark;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataSection;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export review logs & word progress (CSV)'**
  String get settingsExportCsv;

  /// No description provided for @settingsExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export review logs & word progress (JSON)'**
  String get settingsExportJson;

  /// No description provided for @settingsExportSubject.
  ///
  /// In en, this message translates to:
  /// **'My word-learning data'**
  String get settingsExportSubject;

  /// No description provided for @settingsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} file(s)'**
  String settingsExportSuccess(int count);

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings: {error}'**
  String settingsSaveFailed(String error);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About & data sources'**
  String get settingsAbout;

  /// No description provided for @settingsNotificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Enable them in system settings to get daily reminders.'**
  String get settingsNotificationPermissionDenied;

  /// No description provided for @settingsOpenSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsOpenSystemSettings;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to review!'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s new words and reviews.'**
  String get reminderNotificationBody;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'This is a free learning tool. All study data stays on your device and is never uploaded.'**
  String get aboutPrivacyNote;

  /// No description provided for @aboutSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get aboutSourcesTitle;

  /// No description provided for @aboutSourceGaokao.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Education Gaokao English syllabus vocabulary'**
  String get aboutSourceGaokao;

  /// No description provided for @aboutSourceGaokaoDesc.
  ///
  /// In en, this message translates to:
  /// **'Word list scope; ECDICT gk tag used as the seed (no official machine-readable file)'**
  String get aboutSourceGaokaoDesc;

  /// No description provided for @aboutSourceEcdict.
  ///
  /// In en, this message translates to:
  /// **'ECDICT (MIT)'**
  String get aboutSourceEcdict;

  /// No description provided for @aboutSourceEcdictDesc.
  ///
  /// In en, this message translates to:
  /// **'Meanings, parts of speech, fallback phonetics, word-frequency proxy'**
  String get aboutSourceEcdictDesc;

  /// No description provided for @aboutSourceIpa.
  ///
  /// In en, this message translates to:
  /// **'ipa-dict en_US (MIT, based on CMUdict)'**
  String get aboutSourceIpa;

  /// No description provided for @aboutSourceIpaDesc.
  ///
  /// In en, this message translates to:
  /// **'American IPA phonetics (primary source)'**
  String get aboutSourceIpaDesc;

  /// No description provided for @aboutSourceTatoeba.
  ///
  /// In en, this message translates to:
  /// **'Tatoeba English sentences (CC BY 2.0 FR)'**
  String get aboutSourceTatoeba;

  /// No description provided for @aboutSourceTatoebaDesc.
  ///
  /// In en, this message translates to:
  /// **'Example sentences; author attribution stored per word'**
  String get aboutSourceTatoebaDesc;

  /// No description provided for @aboutSourceTts.
  ///
  /// In en, this message translates to:
  /// **'Microsoft Edge TTS (en-US-AriaNeural)'**
  String get aboutSourceTts;

  /// No description provided for @aboutSourceTtsDesc.
  ///
  /// In en, this message translates to:
  /// **'American pronunciation audio generated in bulk'**
  String get aboutSourceTtsDesc;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s results'**
  String get resultsTitle;

  /// No description provided for @resultsCheckinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check-in complete!'**
  String get resultsCheckinSuccess;

  /// No description provided for @resultsSummary.
  ///
  /// In en, this message translates to:
  /// **'Today: {newCount} new words · {reviewCount} reviews'**
  String resultsSummary(int newCount, int reviewCount);

  /// No description provided for @resultsProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s progress'**
  String get resultsProgress;

  /// No description provided for @resultsRemainingNew.
  ///
  /// In en, this message translates to:
  /// **'{count} new words to go'**
  String resultsRemainingNew(int count);

  /// No description provided for @resultsRemainingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews to go'**
  String resultsRemainingReview(int count);

  /// No description provided for @resultsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: about {count} new words'**
  String resultsTomorrow(int count);

  /// No description provided for @resultsEncouragement.
  ///
  /// In en, this message translates to:
  /// **'Keep going — see you tomorrow!'**
  String get resultsEncouragement;

  /// No description provided for @resultsBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get resultsBackHome;

  /// No description provided for @resultsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load today\'s progress: {error}'**
  String resultsLoadFailed(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
