import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/app_review/data/review_storage.dart';
import 'package:pitithpotha/features/app_review/domain/review_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('empty prefs: safe defaults', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = ReviewStorage(await SharedPreferences.getInstance());
    expect(storage.read(), const ReviewState());
  });

  test('corrupt or wrongly-typed values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'review_active_usage_ms': 'lots',
      'review_action_initiated': 'yes',
      'review_native_prompt_version': 7,
      'review_later_count': -4,
      'review_next_eligible_at': 'tomorrow',
    });
    final storage = ReviewStorage(await SharedPreferences.getInstance());
    final state = storage.read();
    expect(state.activeUsage, Duration.zero);
    expect(state.actionInitiated, isFalse);
    expect(state.nativePromptVersion, isNull);
    expect(state.laterCount, 0);
    expect(state.nextEligibleAt, isNull);
  });

  test('negative usage reads as zero', () async {
    SharedPreferences.setMockInitialValues({'review_active_usage_ms': -500});
    final storage = ReviewStorage(await SharedPreferences.getInstance());
    expect(storage.read().activeUsage, Duration.zero);
  });

  test('round-trips through a fresh instance (an app restart)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final saved = ReviewState(
      activeUsage: const Duration(minutes: 3, seconds: 12),
      actionInitiated: true,
      nativePromptVersion: '1.00.03',
      laterCount: 2,
      nextEligibleAt: DateTime.fromMillisecondsSinceEpoch(1_900_000_000_000),
      lastReviewLaterAt: DateTime.fromMillisecondsSinceEpoch(1_899_000_000_000),
      lastReviewPromptAt: DateTime.fromMillisecondsSinceEpoch(
        1_898_000_000_000,
      ),
      reviewPromptCount: 3,
    );
    await ReviewStorage(prefs).write(saved);

    expect(ReviewStorage(prefs).read(), saved);
  });

  test('overlapping writes land in call order', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = ReviewStorage(await SharedPreferences.getInstance());
    final writes = [
      for (var i = 1; i <= 5; i++) storage.write(ReviewState(laterCount: i)),
    ];
    await Future.wait(writes);
    expect(storage.read().laterCount, 5);
  });
}
