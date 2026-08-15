// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wo Ai Bei Dan Ci';

  @override
  String get onboardingTitle => 'Get started';

  @override
  String get onboardingWordbookLabel => 'Choose your wordbook';

  @override
  String get onboardingDailyGoalLabel => 'Daily new words goal (words/day)';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingNoWordbook =>
      'No wordbook available (content pack not installed)';

  @override
  String onboardingLoadFailed(String error) {
    return 'Failed to initialize: $error';
  }

  @override
  String onboardingSaveFailed(String error) {
    return 'Failed to save settings: $error';
  }

  @override
  String get onboardingSkipKnownWords =>
      'Mark words you already know (optional)';

  @override
  String onboardingSkipCount(int count) {
    return '$count word(s) marked';
  }

  @override
  String get skipKnownTitle => 'Mark known words';

  @override
  String get skipKnownSearchHint => 'Search words';

  @override
  String get skipKnownSelectAll => 'Mark all';

  @override
  String get skipKnownClearAll => 'Clear all';

  @override
  String get skipKnownDone => 'Done';

  @override
  String skipKnownSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String skipKnownLoadFailed(String error) {
    return 'Failed to load words: $error';
  }

  @override
  String get skipKnownEmpty => 'No words found';

  @override
  String get homeSkeletonReady => 'Project skeleton is ready.';

  @override
  String get homeTitle => 'Today';

  @override
  String get homeLoading => 'Loading…';

  @override
  String homeLoadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeNoWordbook =>
      'No wordbook available (content pack not installed)';

  @override
  String get homePreparingWordbook => 'Preparing wordbook…';

  @override
  String homeWordbook(String name) {
    return 'Wordbook: $name';
  }

  @override
  String get homeNewWordsLabel => 'New words';

  @override
  String get homeReviewLabel => 'Due reviews';

  @override
  String homeLearnedToday(int count) {
    return 'Learned today: $count words';
  }

  @override
  String homeDeferredHint(int count) {
    return '$count more words deferred to tomorrow';
  }

  @override
  String get homeStartLearning => 'Start learning';

  @override
  String get homeStartReview => 'Start review';

  @override
  String get homeExtraGroupPrompt =>
      'Today\'s learning is done. Learn another set of words?';

  @override
  String get homeExtraGroupConfirm => 'Learn another set';

  @override
  String get homeExtraGroupCancel => 'Cancel';

  @override
  String get homeContinueSession => 'Continue unfinished session';

  @override
  String get homeAllDone => 'Today\'s tasks completed';

  @override
  String get homeEncouragement => 'Keep going — see you tomorrow!';

  @override
  String get learnTitle => 'Learn new words';

  @override
  String get reviewTitle => 'Review';

  @override
  String get sessionLoading => 'Preparing cards…';

  @override
  String sessionLoadFailed(String error) {
    return 'Failed to load session: $error';
  }

  @override
  String sessionFinishFailed(String error) {
    return 'Failed to finish session: $error';
  }

  @override
  String sessionRateFailed(String error) {
    return 'Failed to rate: $error';
  }

  @override
  String get sessionRetry => 'Retry';

  @override
  String get cardTapToFlip => 'Tap the card to see the meaning';

  @override
  String get cardExampleLabel => 'Example';

  @override
  String get cardExampleExpand => 'Show full example';

  @override
  String get cardExampleCollapse => 'Collapse example';

  @override
  String get rateAgain => 'Don\'t know';

  @override
  String get rateHard => 'Not sure';

  @override
  String get rateGood => 'Know it';

  @override
  String feedbackAgain(String word) {
    return 'Don\'t know: $word (will appear again)';
  }

  @override
  String feedbackHard(String word) {
    return 'Not sure: $word';
  }

  @override
  String feedbackGood(String word) {
    return 'Know it: $word';
  }

  @override
  String get audioUnavailable => 'Audio not available yet';

  @override
  String get audioPlay => 'Play pronunciation';

  @override
  String get audioDownloadNotificationTitle => 'Downloading pronunciation pack';

  @override
  String get audioDownloadNotificationText =>
      'Downloading audio; offline playback available when finished';

  @override
  String get audioDownloadNotificationChannelName =>
      'Pronunciation pack download';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGoalSection => 'Study goal';

  @override
  String get settingsDailyGoal => 'Daily new words';

  @override
  String get settingsReviewCap => 'Daily review cap';

  @override
  String get settingsReviewCapHint =>
      'Overdue reviews above the cap are deferred to tomorrow';

  @override
  String get settingsReviewCapOff => 'Off';

  @override
  String get settingsPronunciationSection => 'Audio';

  @override
  String get settingsPronunciation => 'Pronunciation';

  @override
  String get settingsCellularDownload => 'Download audio on mobile data';

  @override
  String get settingsCellularDownloadHint =>
      'Off by default to save data; downloads start on Wi-Fi';

  @override
  String get settingsReminderSection => 'Daily reminder';

  @override
  String get settingsReminder => 'Enable daily reminder';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkSystem => 'System';

  @override
  String get settingsDarkLight => 'Light';

  @override
  String get settingsDarkDark => 'Dark';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsExportCsv => 'Export review logs & word progress (CSV)';

  @override
  String get settingsExportJson => 'Export review logs & word progress (JSON)';

  @override
  String get settingsExportSubject => 'My word-learning data';

  @override
  String settingsExportSuccess(int count) {
    return 'Exported $count file(s)';
  }

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsSaveFailed(String error) {
    return 'Failed to save settings: $error';
  }

  @override
  String get settingsAbout => 'About & data sources';

  @override
  String get settingsNotificationPermissionDenied =>
      'Notifications are disabled. Enable them in system settings to get daily reminders.';

  @override
  String get settingsOpenSystemSettings => 'Open settings';

  @override
  String get reminderNotificationTitle => 'Time to review!';

  @override
  String get reminderNotificationBody =>
      'Complete today\'s new words and reviews.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutPrivacyNote =>
      'This is a free learning tool. All study data stays on your device and is never uploaded.';

  @override
  String get aboutSourcesTitle => 'Data sources';

  @override
  String get aboutSourceGaokao =>
      'Ministry of Education Gaokao English syllabus vocabulary';

  @override
  String get aboutSourceGaokaoDesc =>
      'Word list scope; ECDICT gk tag used as the seed (no official machine-readable file)';

  @override
  String get aboutSourceEcdict => 'ECDICT (MIT)';

  @override
  String get aboutSourceEcdictDesc =>
      'Meanings, parts of speech, fallback phonetics, word-frequency proxy';

  @override
  String get aboutSourceIpa => 'ipa-dict en_US (MIT, based on CMUdict)';

  @override
  String get aboutSourceIpaDesc => 'American IPA phonetics (primary source)';

  @override
  String get aboutSourceTatoeba => 'Tatoeba English sentences (CC BY 2.0 FR)';

  @override
  String get aboutSourceTatoebaDesc =>
      'Example sentences; author attribution stored per word';

  @override
  String get aboutSourceTts => 'Microsoft Edge TTS (en-US-AriaNeural)';

  @override
  String get aboutSourceTtsDesc =>
      'American pronunciation audio generated in bulk';

  @override
  String get resultsTitle => 'Today\'s results';

  @override
  String get resultsCheckinSuccess => 'Check-in complete!';

  @override
  String resultsSummary(int newCount, int reviewCount) {
    return 'Today: $newCount new words · $reviewCount reviews';
  }

  @override
  String get resultsProgress => 'Today\'s progress';

  @override
  String resultsRemainingNew(int count) {
    return '$count new words to go';
  }

  @override
  String resultsRemainingReview(int count) {
    return '$count reviews to go';
  }

  @override
  String resultsTomorrow(int count) {
    return 'Tomorrow: about $count new words';
  }

  @override
  String get resultsEncouragement => 'Keep going — see you tomorrow!';

  @override
  String get resultsBackHome => 'Back to home';

  @override
  String resultsLoadFailed(String error) {
    return 'Failed to load today\'s progress: $error';
  }
}
