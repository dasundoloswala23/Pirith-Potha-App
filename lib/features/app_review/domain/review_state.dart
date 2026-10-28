import 'package:equatable/equatable.dart';

/// Everything the review scheduler remembers about this installation.
///
/// Local-only: survives restarts, app updates and leaving the app, but not
/// an uninstall or "clear app data" — which simply starts the cycle over.
class ReviewState extends Equatable {
  const ReviewState({
    this.activeUsage = Duration.zero,
    this.actionInitiated = false,
    this.nativePromptVersion,
    this.laterCount = 0,
    this.nextEligibleAt,
    this.lastReviewLaterAt,
    this.lastReviewPromptAt,
    this.reviewPromptCount = 0,
  });

  /// Cumulative foreground time while on an eligible screen for the current cycle.
  final Duration activeUsage;

  /// Whether the user tapped "Rate App" and store navigation was initiated.
  /// Once true, never show again.
  final bool actionInitiated;

  /// iOS: the app version the native StoreKit prompt was last requested on.
  /// "Requested", not "shown" — StoreKit never says.
  final String? nativePromptVersion;

  /// Times the user chose "Maybe Later".
  final int laterCount;

  /// End of the current cooldown, or null before the first "Maybe Later".
  final DateTime? nextEligibleAt;

  /// Timestamp when "Maybe Later" was last tapped.
  final DateTime? lastReviewLaterAt;

  /// Timestamp when the review prompt was last displayed.
  final DateTime? lastReviewPromptAt;

  /// Number of times a review prompt has been displayed.
  final int reviewPromptCount;

  ReviewState copyWith({
    Duration? activeUsage,
    bool? actionInitiated,
    String? nativePromptVersion,
    int? laterCount,
    DateTime? nextEligibleAt,
    DateTime? lastReviewLaterAt,
    DateTime? lastReviewPromptAt,
    int? reviewPromptCount,
  }) => ReviewState(
    activeUsage: activeUsage ?? this.activeUsage,
    actionInitiated: actionInitiated ?? this.actionInitiated,
    nativePromptVersion: nativePromptVersion ?? this.nativePromptVersion,
    laterCount: laterCount ?? this.laterCount,
    nextEligibleAt: nextEligibleAt ?? this.nextEligibleAt,
    lastReviewLaterAt: lastReviewLaterAt ?? this.lastReviewLaterAt,
    lastReviewPromptAt: lastReviewPromptAt ?? this.lastReviewPromptAt,
    reviewPromptCount: reviewPromptCount ?? this.reviewPromptCount,
  );

  @override
  List<Object?> get props => [
    activeUsage,
    actionInitiated,
    nativePromptVersion,
    laterCount,
    nextEligibleAt,
    lastReviewLaterAt,
    lastReviewPromptAt,
    reviewPromptCount,
  ];
}
