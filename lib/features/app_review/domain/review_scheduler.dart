import 'review_state.dart';

/// When the automatic review invitation may appear. Pure — every method
/// takes `now` — so tests can jump days ahead without waiting.
///
/// - First invitation: after [usageThreshold] of cumulative active use.
/// - After "Maybe Later": [firstCooldown] the first time, [laterCooldown]
///   every time after, measured from the tap. No second usage wait once a
///   cooldown ends — the next safe moment is enough.
/// - Once the user has opened the store from the invitation: never again.
class ReviewScheduler {
  const ReviewScheduler({
    this.usageThreshold = const Duration(minutes: 5),
    this.firstCooldown = const Duration(hours: 34),
    this.laterCooldown = const Duration(hours: 24),
  });

  /// Standard constants for review scheduling.
  static const Duration defaultUsageThreshold = Duration(minutes: 5);
  static const Duration defaultFirstCooldown = Duration(hours: 34);
  static const Duration defaultLaterCooldown = Duration(hours: 24);

  final Duration usageThreshold;
  final Duration firstCooldown;
  final Duration laterCooldown;

  bool isEligible(ReviewState state, DateTime now) {
    if (state.actionInitiated) return false;
    if (state.laterCount > 0) {
      final next = normalizedNextEligibleAt(state, now);
      if (now.isBefore(next)) return false;
    }
    return state.activeUsage >= usageThreshold;
  }

  /// Time left before the usage threshold, or zero once reached.
  Duration usageRemaining(ReviewState state) {
    final left = usageThreshold - state.activeUsage;
    return left.isNegative ? Duration.zero : left;
  }

  ReviewState afterLater(ReviewState state, DateTime now) {
    final count = state.laterCount + 1;
    return state.copyWith(
      laterCount: count,
      nextEligibleAt: now.add(_cooldownFor(count)),
      lastReviewLaterAt: now,
      activeUsage: Duration.zero,
    );
  }

  ReviewState afterStoreOpened(ReviewState state) =>
      state.copyWith(actionInitiated: true);

  ReviewState afterPromptShown(ReviewState state, DateTime now) =>
      state.copyWith(
        lastReviewPromptAt: now,
        reviewPromptCount: state.reviewPromptCount + 1,
      );

  /// [state] with a repaired cooldown end, for persisting once on load —
  /// otherwise a missing value would be re-clamped to "one cooldown from
  /// now" on every check and never arrive.
  ReviewState normalize(ReviewState state, DateTime now) {
    if (state.laterCount == 0) return state;
    final next = normalizedNextEligibleAt(state, now);
    return next == state.nextEligibleAt
        ? state
        : state.copyWith(nextEligibleAt: next);
  }

  /// [ReviewState.nextEligibleAt], repaired for a clock that moved
  /// backwards (the stored time is further away than any cooldown could
  /// be) or a missing value: clamped to one cooldown from [now], so the
  /// user is neither locked out for months nor prompted immediately.
  DateTime normalizedNextEligibleAt(ReviewState state, DateTime now) {
    final cooldown = _cooldownFor(state.laterCount);
    final stored = state.nextEligibleAt;
    final latestPossible = now.add(cooldown);
    if (stored == null || stored.isAfter(latestPossible)) return latestPossible;
    return stored;
  }

  Duration _cooldownFor(int laterCount) =>
      laterCount <= 1 ? firstCooldown : laterCooldown;
}
