import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/app_review/domain/review_scheduler.dart';
import 'package:pitithpotha/features/app_review/domain/review_state.dart';

void main() {
  const scheduler = ReviewScheduler();
  final now = DateTime(2026, 10, 27, 9);

  group('first invitation', () {
    test('not at 4:59 of active use', () {
      const state = ReviewState(activeUsage: Duration(minutes: 4, seconds: 59));
      expect(scheduler.isEligible(state, now), isFalse);
    });

    test('at exactly 5:00', () {
      const state = ReviewState(activeUsage: Duration(minutes: 5));
      expect(scheduler.isEligible(state, now), isTrue);
    });

    test('usageRemaining counts down to zero, never negative', () {
      expect(
        scheduler.usageRemaining(const ReviewState(activeUsage: Duration(minutes: 2))),
        const Duration(minutes: 3),
      );
      expect(
        scheduler.usageRemaining(const ReviewState(activeUsage: Duration(minutes: 9))),
        Duration.zero,
      );
    });
  });

  group('Maybe Later', () {
    const ready = ReviewState(activeUsage: Duration(minutes: 5));

    test('first Later: exactly 34 hours from the tap', () {
      final later = scheduler.afterLater(ready, now);
      expect(later.laterCount, 1);
      expect(later.nextEligibleAt, now.add(const Duration(hours: 34)));
    });

    test('second and every later Later: exactly 24 hours', () {
      var state = scheduler.afterLater(ready, now);
      for (var i = 2; i <= 5; i++) {
        final tap = now.add(Duration(days: i * 2));
        state = scheduler.afterLater(state, tap);
        expect(state.laterCount, i);
        expect(state.nextEligibleAt, tap.add(const Duration(hours: 24)));
      }
    });

    test('ineligible during the cooldown, eligible after cooldown once usage met', () {
      final later = scheduler.afterLater(ready, now);
      expect(scheduler.isEligible(later, now.add(const Duration(hours: 33, minutes: 59))), isFalse);
      expect(scheduler.isEligible(later, now.add(const Duration(hours: 34))), isFalse,
          reason: 'needs 5 minutes of usage in the new session');
      final withUsage = later.copyWith(activeUsage: const Duration(minutes: 5));
      expect(scheduler.isEligible(withUsage, now.add(const Duration(hours: 34))), isTrue);
      expect(scheduler.isEligible(withUsage, now.add(const Duration(days: 10))), isTrue,
          reason: 'cooldown expired while the app was closed and usage met');
    });
  });

  test('store opened: never eligible again', () {
    final opened = scheduler.afterStoreOpened(
      const ReviewState(activeUsage: Duration(hours: 9), laterCount: 3),
    );
    expect(opened.actionInitiated, isTrue);
    expect(scheduler.isEligible(opened, now.add(const Duration(days: 999))), isFalse);
  });

  group('clock changes and bad data', () {
    test('a cooldown end pushed far into the future (clock moved back) is '
        'clamped to one cooldown from now', () {
      final state = ReviewState(
        activeUsage: const Duration(minutes: 5),
        laterCount: 1,
        nextEligibleAt: now.add(const Duration(days: 400)),
      );
      expect(
        scheduler.normalizedNextEligibleAt(state, now),
        now.add(const Duration(hours: 34)),
      );
      expect(scheduler.normalize(state, now).nextEligibleAt, now.add(const Duration(hours: 34)));
    });

    test('a missing cooldown end after a Later is repaired, not fired '
        'immediately', () {
      const state = ReviewState(activeUsage: Duration(minutes: 5), laterCount: 2);
      final normalized = scheduler.normalize(state, now);
      expect(normalized.nextEligibleAt, now.add(const Duration(hours: 24)));
      expect(scheduler.isEligible(normalized, now), isFalse);
      expect(scheduler.isEligible(normalized, now.add(const Duration(hours: 24))), isTrue);
    });

    test('a valid cooldown end is left alone', () {
      final state = ReviewState(
        laterCount: 1,
        nextEligibleAt: now.add(const Duration(hours: 3)),
      );
      expect(scheduler.normalize(state, now), state);
    });
  });
}
