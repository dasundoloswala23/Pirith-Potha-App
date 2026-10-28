import 'dart:async';

import 'package:flutter/widgets.dart';

/// Measures foreground time only, from a monotonic clock — a wall-clock
/// change while the app is open can't add or remove usage.
///
/// No periodic work: elapsed time is read on demand ([pending]) and handed
/// over ([onFlush]) only when the app leaves the foreground, and a single
/// one-shot timer fires at the moment the remaining threshold runs out.
class UsageTracker {
  UsageTracker({
    Duration Function()? monotonicNow,
    Timer Function(Duration, void Function())? timerFactory,
  }) : _now = monotonicNow ?? _defaultMonotonic,
       _timerFactory = timerFactory ?? Timer.new;

  static final _monotonic = Stopwatch()..start();
  static Duration _defaultMonotonic() => _monotonic.elapsed;

  final Duration Function() _now;
  final Timer Function(Duration, void Function()) _timerFactory;

  /// Receives foreground time accumulated since the last flush.
  void Function(Duration elapsed)? onFlush;

  /// Fires once the remaining time passed to [start] has been spent in the
  /// foreground.
  VoidCallback? onThreshold;

  bool _enabled = false;
  bool _foreground = true;
  Duration? _runningSince;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  bool get isRunning => _runningSince != null;

  /// Foreground time not yet flushed.
  Duration get pending {
    final since = _runningSince;
    return since == null ? Duration.zero : _now() - since;
  }

  /// Begins counting. [remaining] is the time still needed to reach the
  /// threshold; zero means only flushing is wanted, no threshold callback.
  void start(Duration remaining) {
    _enabled = true;
    _remaining = remaining;
    if (_foreground) _resume();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (!_enabled) return;
    if (foreground) {
      _resume();
    } else {
      _pause();
    }
  }

  /// Hands over the pending time without stopping the count.
  void flush() {
    final elapsed = pending;
    if (_runningSince != null) _runningSince = _now();
    _remaining -= elapsed;
    if (elapsed > Duration.zero) onFlush?.call(elapsed);
  }

  void stop() {
    _pause();
    _enabled = false;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _resume() {
    if (_runningSince != null) return;
    _runningSince = _now();
    if (_remaining > Duration.zero) {
      _timer?.cancel();
      _timer = _timerFactory(_remaining, _fire);
    }
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    if (_runningSince == null) return;
    flush();
    _runningSince = null;
  }

  void _fire() {
    _timer = null;
    flush();
    _remaining = Duration.zero;
    onThreshold?.call();
  }
}
