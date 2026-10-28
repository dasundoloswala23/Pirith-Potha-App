import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/review_state.dart';

/// Persists [ReviewState] in [SharedPreferences] — the same store, and the
/// same direct-key style, as every other small piece of local state here.
///
/// Reads are defensive: a missing key, a value of the wrong type (another
/// build wrote it differently), or a negative number all fall back to the
/// default rather than throwing. Writes are chained so two saves started
/// close together (lifecycle pause racing a "Maybe Later" tap) land in
/// order instead of interleaving.
class ReviewStorage {
  ReviewStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _usageKey = 'review_active_usage_ms';
  static const _actionKey = 'review_action_initiated';
  static const _nativeVersionKey = 'review_native_prompt_version';
  static const _laterCountKey = 'review_later_count';
  static const _nextEligibleKey = 'review_next_eligible_at';
  static const _lastLaterKey = 'review_last_later_at';
  static const _lastPromptKey = 'review_last_prompt_at';
  static const _promptCountKey = 'review_prompt_count';

  Future<void> _pending = Future.value();

  ReviewState read() {
    final usageMs = _int(_usageKey);
    final nextMs = _prefs.get(_nextEligibleKey);
    final native = _prefs.get(_nativeVersionKey);
    final lastLaterMs = _prefs.get(_lastLaterKey);
    final lastPromptMs = _prefs.get(_lastPromptKey);
    return ReviewState(
      activeUsage: Duration(milliseconds: usageMs < 0 ? 0 : usageMs),
      actionInitiated: _prefs.get(_actionKey) == true,
      nativePromptVersion: native is String && native.isNotEmpty
          ? native
          : null,
      laterCount: _int(_laterCountKey).clamp(0, 1 << 20),
      nextEligibleAt: nextMs is int && nextMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(nextMs)
          : null,
      lastReviewLaterAt: lastLaterMs is int && lastLaterMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastLaterMs)
          : null,
      lastReviewPromptAt: lastPromptMs is int && lastPromptMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastPromptMs)
          : null,
      reviewPromptCount: _int(_promptCountKey).clamp(0, 1 << 20),
    );
  }

  Future<void> write(ReviewState state) {
    final next = _pending.then((_) => _write(state));
    // A failed write mustn't poison every later one.
    _pending = next.catchError((Object _) {});
    return next;
  }

  Future<void> _write(ReviewState state) async {
    await _prefs.setInt(_usageKey, state.activeUsage.inMilliseconds);
    await _prefs.setBool(_actionKey, state.actionInitiated);
    await _prefs.setInt(_laterCountKey, state.laterCount);
    await _prefs.setInt(_promptCountKey, state.reviewPromptCount);
    final native = state.nativePromptVersion;
    if (native == null) {
      await _prefs.remove(_nativeVersionKey);
    } else {
      await _prefs.setString(_nativeVersionKey, native);
    }
    final next = state.nextEligibleAt;
    if (next == null) {
      await _prefs.remove(_nextEligibleKey);
    } else {
      await _prefs.setInt(_nextEligibleKey, next.millisecondsSinceEpoch);
    }
    final lastLater = state.lastReviewLaterAt;
    if (lastLater == null) {
      await _prefs.remove(_lastLaterKey);
    } else {
      await _prefs.setInt(_lastLaterKey, lastLater.millisecondsSinceEpoch);
    }
    final lastPrompt = state.lastReviewPromptAt;
    if (lastPrompt == null) {
      await _prefs.remove(_lastPromptKey);
    } else {
      await _prefs.setInt(_lastPromptKey, lastPrompt.millisecondsSinceEpoch);
    }
  }

  int _int(String key) {
    final value = _prefs.get(key);
    return value is int ? value : 0;
  }
}
