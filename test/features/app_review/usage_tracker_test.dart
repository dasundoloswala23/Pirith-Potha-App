import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/app_review/presentation/usage_tracker.dart';

/// A tracker on fake time: the monotonic clock is the fake zone's elapsed
/// time, and its one-shot timer is a real (fake-zone) Timer.
UsageTracker _tracker(FakeAsync async) =>
    UsageTracker(monotonicNow: () => async.elapsed, timerFactory: Timer.new);

void main() {
  test('foreground time is flushed when the app backgrounds', () {
    fakeAsync((async) {
      final flushed = <Duration>[];
      final tracker = _tracker(async)..onFlush = flushed.add;
      tracker.start(const Duration(minutes: 5));

      async.elapse(const Duration(minutes: 2));
      tracker.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(flushed, [const Duration(minutes: 2)]);
      tracker.dispose();
    });
  });

  test('background time is excluded', () {
    fakeAsync((async) {
      final flushed = <Duration>[];
      final tracker = _tracker(async)..onFlush = flushed.add;
      tracker.start(const Duration(minutes: 5));

      async.elapse(const Duration(minutes: 1));
      tracker.didChangeAppLifecycleState(AppLifecycleState.inactive);
      async.elapse(const Duration(hours: 3)); // locked / in another app
      tracker.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.elapse(const Duration(minutes: 1));
      tracker.didChangeAppLifecycleState(AppLifecycleState.paused);

      final total = flushed.fold(Duration.zero, (a, b) => a + b);
      expect(total, const Duration(minutes: 2));
      tracker.dispose();
    });
  });

  test('2 min, close, then 3 min in a later session reaches the threshold', () {
    fakeAsync((async) {
      var stored = Duration.zero;
      var reached = false;

      // Session 1.
      final first = _tracker(async)..onFlush = (d) => stored += d;
      first.start(const Duration(minutes: 5) - stored);
      async.elapse(const Duration(minutes: 2));
      first.didChangeAppLifecycleState(AppLifecycleState.detached);
      first.dispose();
      expect(stored, const Duration(minutes: 2));
      expect(reached, isFalse);

      // App closed for a day.
      async.elapse(const Duration(days: 1));

      // Session 2: a fresh tracker resumes from the stored total.
      final second = _tracker(async)
        ..onFlush = ((d) => stored += d)
        ..onThreshold = (() => reached = true);
      second.start(const Duration(minutes: 5) - stored);
      async.elapse(const Duration(minutes: 2, seconds: 59));
      expect(reached, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(reached, isTrue);
      expect(stored, const Duration(minutes: 5));
      second.dispose();
    });
  });

  test('the threshold timer does not run while backgrounded', () {
    fakeAsync((async) {
      var reached = false;
      final tracker = _tracker(async)..onThreshold = () => reached = true;
      tracker.start(const Duration(minutes: 5));

      async.elapse(const Duration(minutes: 4));
      tracker.didChangeAppLifecycleState(AppLifecycleState.paused);
      async.elapse(const Duration(hours: 1));
      expect(reached, isFalse);

      tracker.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.elapse(const Duration(minutes: 1));
      expect(reached, isTrue);
      tracker.dispose();
    });
  });

  test('no periodic work: nothing is scheduled after the threshold', () {
    fakeAsync((async) {
      final tracker = _tracker(async);
      tracker.start(const Duration(seconds: 10));
      async.elapse(const Duration(seconds: 10));
      expect(async.pendingTimers, isEmpty);
      tracker.dispose();
    });
  });

  test('nothing is counted before start()', () {
    fakeAsync((async) {
      final flushed = <Duration>[];
      final tracker = _tracker(async)..onFlush = flushed.add;
      async.elapse(const Duration(minutes: 10));
      tracker.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(flushed, isEmpty);
      tracker.dispose();
    });
  });
}
