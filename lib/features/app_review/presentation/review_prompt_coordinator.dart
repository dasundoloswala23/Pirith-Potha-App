import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/errors/error_reporter.dart';
import '../../../core/firebase/analytics_service.dart';
import '../data/native_review_api.dart';
import '../data/review_storage.dart';
import '../data/review_store_launcher.dart';
import '../domain/review_scheduler.dart';
import '../domain/review_state.dart';
import 'usage_tracker.dart';

/// What the user did with the review invitation sheet.
enum ReviewSheetOutcome { storeOpened, later }

/// The widget that can put UI on screen — host implementation for review prompt.
/// The coordinator never holds a `BuildContext`; it asks the host instead, and
/// the host answers with its own mounted context.
abstract interface class ReviewPromptHost {
  /// Whether right now is a safe moment: the main experience is the top
  /// route (nothing pushed over it — no dialog or modal sheet).
  bool get isSafeMoment;

  /// Shows the invitation sheet. [openStore] opens Google Play / App Store
  /// and reports whether it worked; the sheet only closes as "store opened" on success.
  Future<ReviewSheetOutcome> presentInvitation({
    required Future<bool> Function() openStore,
  });
}

/// Central business logic for the automatic review request.
///
/// Android & iOS: a beautiful custom invitation sheet, scheduled by [ReviewScheduler]
/// (5 minutes of active foreground use, then 34 h / 24 h cooldowns after "Maybe Later",
/// never again once the user opens the store from it).
class ReviewPromptCoordinator {
  ReviewPromptCoordinator({
    required ReviewStorage storage,
    ReviewScheduler scheduler = const ReviewScheduler(),
    NativeReviewApi native = const InAppReviewApi(),
    ReviewStoreLauncher? storeLauncher,
    UsageTracker? tracker,
    DateTime Function()? clock,
    TargetPlatform Function()? platform,
    Future<String> Function()? installedVersion,
    AnalyticsService? analytics,
  }) : _storage = storage,
       _scheduler = scheduler,
       _native = native,
       _launcher = storeLauncher ??
           DefaultReviewStoreLauncher(
             native: native,
             platform: platform ?? (() => defaultTargetPlatform),
           ),
       _tracker = tracker ?? UsageTracker(),
       _clock = clock ?? DateTime.now,
       _platform = platform ?? (() => defaultTargetPlatform),
       _installedVersion = installedVersion ?? _packageVersion,
       _analytics = analytics {
    _tracker
      ..onFlush = _addUsage
      ..onThreshold = () => unawaited(tryPrompt());
  }

  final ReviewStorage _storage;
  final ReviewScheduler _scheduler;
  final NativeReviewApi _native;
  final ReviewStoreLauncher _launcher;
  final UsageTracker _tracker;
  final DateTime Function() _clock;
  final TargetPlatform Function() _platform;
  final Future<String> Function() _installedVersion;
  final AnalyticsService? _analytics;

  static Future<String> _packageVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  ReviewState? _state;
  final List<ReviewPromptHost> _hosts = [];
  bool _foreground = true;
  bool _inFlight = false;
  bool _handledThisSession = false;

  ReviewPromptHost? get _host => _hosts.isNotEmpty ? _hosts.last : null;

  @visibleForTesting
  ReviewState? get state => _state;

  bool get _supported =>
      _platform() == TargetPlatform.android || _platform() == TargetPlatform.iOS;

  /// Called by the host when an eligible screen mounts.
  void attach(ReviewPromptHost host) {
    if (!_hosts.contains(host)) _hosts.add(host);
    if (_state == null && _supported) {
      try {
        final now = _clock();
        final loaded = _storage.read();
        final normalized = _scheduler.normalize(loaded, now);
        _state = normalized;
        if (normalized != loaded) unawaited(_storage.write(normalized));
        if (!normalized.actionInitiated) {
          final isPastCooldown = normalized.laterCount == 0 ||
              !now.isBefore(_scheduler.normalizedNextEligibleAt(normalized, now));
          if (isPastCooldown) {
            _tracker.start(_scheduler.usageRemaining(normalized));
          }
        }
      } catch (error, stackTrace) {
        reportNonFatal(error, stackTrace, reason: 'Review state load failed');
      }
    }
    unawaited(tryPrompt());
  }

  void detach(ReviewPromptHost host) {
    _hosts.remove(host);
  }

  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    _foreground = lifecycle == AppLifecycleState.resumed;
    _tracker.didChangeAppLifecycleState(lifecycle);
    if (_foreground) {
      final state = _state;
      if (state != null && !state.actionInitiated && !_tracker.isRunning) {
        final now = _clock();
        final isPastCooldown = state.laterCount == 0 ||
            !now.isBefore(_scheduler.normalizedNextEligibleAt(state, now));
        if (isPastCooldown) {
          _tracker.start(_scheduler.usageRemaining(state));
        }
      }
      unawaited(tryPrompt());
    }
  }

  /// Shows the invitation sheet if it is due and now is a safe moment.
  Future<void> tryPrompt() async {
    final state = _state;
    final host = _host;
    if (state == null || host == null) return;
    if (_inFlight || _handledThisSession || !_foreground) return;
    if (!host.isSafeMoment) return;

    final live = state.copyWith(activeUsage: state.activeUsage + _tracker.pending);
    if (!_scheduler.isEligible(live, _clock())) return;

    _inFlight = true;
    _handledThisSession = true;
    try {
      await _presentInvitation(host);
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Review prompt failed');
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _presentInvitation(ReviewPromptHost host) async {
    unawaited(_analytics?.logReviewPromptTriggered('automatic'));
    await _save(_scheduler.afterPromptShown(_current, _clock()));
    final outcome = await host.presentInvitation(openStore: _openStore);
    if (outcome == ReviewSheetOutcome.later) {
      await _save(_scheduler.afterLater(_current, _clock()));
      unawaited(_analytics?.logReviewInvitationAction('later'));
      _tracker.stop();
    }
  }

  /// Marks the flow done only after the store actually opened.
  Future<bool> _openStore() async {
    try {
      final opened = await _launcher.openStore();
      if (!opened) return false;
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Opening store listing failed');
      return false;
    }
    _tracker.stop();
    await _save(_scheduler.afterStoreOpened(_current));
    unawaited(_analytics?.logReviewInvitationAction('rate'));
    return true;
  }

  /// Optional native StoreKit review prompt presentation mode.
  Future<void> requestNativeReview() async {
    final version = await _installedVersion();
    if (_current.nativePromptVersion == version) return;
    await _save(_current.copyWith(nativePromptVersion: version));
    _tracker.stop();
    if (!await _native.isAvailable()) return;
    await _native.requestReview();
    unawaited(_analytics?.logReviewPromptTriggered('automatic_native'));
  }

  ReviewState get _current => _state ?? const ReviewState();

  void _addUsage(Duration elapsed) {
    final state = _state;
    if (state == null) return;
    final next = state.copyWith(activeUsage: state.activeUsage + elapsed);
    _state = next;
    unawaited(_storage.write(next).catchError(_reportWrite));
    if (_scheduler.usageRemaining(next) == Duration.zero) _tracker.stop();
  }

  Future<void> _save(ReviewState next) async {
    _state = next;
    await _storage.write(next).catchError(_reportWrite);
  }

  void _reportWrite(Object error, StackTrace stackTrace) =>
      reportNonFatal(error, stackTrace, reason: 'Review state save failed');

  void dispose() => _tracker.dispose();
}
