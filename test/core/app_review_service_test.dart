import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/services/app_review_service.dart';

// Only the manual Settings path lives here now; the automatic, usage-based
// request is ReviewPromptCoordinator's (test/features/app_review).
//
// InAppReview.instance has no platform channel under `flutter test` and
// throws MissingPluginException, which the service must swallow.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(AppReviewService.resetForTest);

  test('promptFromSettings never throws, configured or not', () async {
    await AppReviewService.promptFromSettings();
    AppReviewService.configure();
    await AppReviewService.promptFromSettings();
  });
}
