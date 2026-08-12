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
  String homeWordbook(String name) {
    return 'Wordbook: $name';
  }

  @override
  String get homeNewWordsLabel => 'New words';

  @override
  String get homeReviewLabel => 'Due reviews';

  @override
  String homeDeferredHint(int count) {
    return '$count more words deferred to tomorrow';
  }

  @override
  String get homeStartLearning => 'Start learning';

  @override
  String get homeStartReview => 'Start review';

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
