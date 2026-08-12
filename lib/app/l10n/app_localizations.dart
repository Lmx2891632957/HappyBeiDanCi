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
