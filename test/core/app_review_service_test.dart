import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pitithpotha/core/services/app_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// AppReviewService talks to the real InAppReview.instance, which has no
// platform channel registered under `flutter test` and so throws
// MissingPluginException — caught internally and reported non-fatally. That
// makes the *native call* unobservable here, which is fine: the thing this
// suite actually needs to prove is the persistence layer around it — that
// an attempt is recorded before the call, so a second call this version is
// a guaranteed no-op regardless of what the native side does.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Pirith Potha',
      packageName: 'com.pirith.pitithpotha',
      version: '1.00.02',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  tearDown(AppReviewService.resetForTest);

  group('AppReviewService.maybePromptAfterPositiveMoment', () {
    test('does nothing before configure() has run', () async {
      // No SharedPreferences.setMockInitialValues / configure() call in
      // this test — mirrors a widget test that never calls
      // configureDependencies(), which must not crash.
      await AppReviewService.maybePromptAfterPositiveMoment();
      // No assertion beyond "didn't throw" — there's nothing to read back.
    });

    test('records an attempt for the current version', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      AppReviewService.configure(prefs);

      await AppReviewService.maybePromptAfterPositiveMoment();

      expect(prefs.getString('review_prompted_version'), '1.00.02');
    });

    test('a second call the same version does not throw', () async {
      SharedPreferences.setMockInitialValues({
        'review_prompted_version': '1.00.02',
      });
      final prefs = await SharedPreferences.getInstance();
      AppReviewService.configure(prefs);

      // Already capped — this should return immediately without touching
      // the native plugin at all.
      await AppReviewService.maybePromptAfterPositiveMoment();

      expect(prefs.getString('review_prompted_version'), '1.00.02');
    });

    test('a version bump allows another attempt', () async {
      SharedPreferences.setMockInitialValues({
        'review_prompted_version': '1.00.01',
      });
      final prefs = await SharedPreferences.getInstance();
      AppReviewService.configure(prefs);

      await AppReviewService.maybePromptAfterPositiveMoment();

      expect(prefs.getString('review_prompted_version'), '1.00.02');
    });
  });

  group('AppReviewService.promptFromSettings', () {
    test('never throws even with no configure() call', () async {
      await AppReviewService.promptFromSettings();
    });
  });
}
