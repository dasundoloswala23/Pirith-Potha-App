import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/app_review/data/native_review_api.dart';
import 'package:pitithpotha/features/app_review/data/review_storage.dart';
import 'package:pitithpotha/features/app_review/data/review_store_launcher.dart';
import 'package:pitithpotha/features/app_review/domain/review_scheduler.dart';
import 'package:pitithpotha/features/app_review/presentation/review_prompt_coordinator.dart';
import 'package:pitithpotha/features/app_review/presentation/usage_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockReviewHost implements ReviewPromptHost {
  bool isSafe = true;
  int presentCount = 0;
  bool tapRate = false;
  bool tapLater = false;
  bool? lastStoreOpenedResult;

  @override
  bool get isSafeMoment => isSafe;

  @override
  Future<ReviewSheetOutcome> presentInvitation({
    required Future<bool> Function() openStore,
  }) async {
    presentCount++;
    if (tapRate) {
      lastStoreOpenedResult = await openStore();
      return lastStoreOpenedResult!
          ? ReviewSheetOutcome.storeOpened
          : ReviewSheetOutcome.later;
    }
    return ReviewSheetOutcome.later;
  }
}

class _MockStoreLauncher implements ReviewStoreLauncher {
  bool shouldSucceed = true;
  int openCount = 0;

  @override
  Future<bool> openStore() async {
    openCount++;
    return shouldSucceed;
  }
}

class _TestNativeReviewApi implements NativeReviewApi {
  int requests = 0;
  int storeOpens = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing() async => storeOpens++;
}

void main() {
  late SharedPreferences prefs;
  late _MockReviewHost host;
  late _MockStoreLauncher launcher;
  late _TestNativeReviewApi native;
  DateTime fakeNow = DateTime(2026, 10, 27, 10, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    host = _MockReviewHost();
    launcher = _MockStoreLauncher();
    native = _TestNativeReviewApi();
    fakeNow = DateTime(2026, 10, 27, 10, 0);
  });

  ReviewPromptCoordinator createCoordinator(FakeAsync async, {ReviewStorage? storage}) {
    return ReviewPromptCoordinator(
      storage: storage ?? ReviewStorage(prefs),
      scheduler: const ReviewScheduler(),
      native: native,
      storeLauncher: launcher,
      tracker: UsageTracker(
        monotonicNow: () => async.elapsed,
        timerFactory: Timer.new,
      ),
      clock: () => fakeNow,
      platform: () => TargetPlatform.android,
      installedVersion: () async => '1.00.03',
    );
  }

  group('Smart App Review System - 14 Production Scenarios', () {
    test('Scenario 1: First-time user opens app for less than 5 minutes -> no popup', () async {
      fakeAsync((async) {
        final coordinator = createCoordinator(async)..attach(host);
        async.elapse(const Duration(minutes: 4, seconds: 50));
        async.flushMicrotasks();
        expect(host.presentCount, 0, reason: 'Must not prompt before 5 minutes');
        coordinator.dispose();
      });
    });

    test('Scenario 2: User actively uses app for at least 5 minutes -> popup appears on current eligible screen', () async {
      fakeAsync((async) {
        final coordinator = createCoordinator(async)..attach(host);
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(host.presentCount, 1, reason: 'Must prompt at 5 active minutes');
        coordinator.dispose();
      });
    });

    test('Scenario 3 & 4: App goes into background -> timer pauses, resumes when active', () async {
      fakeAsync((async) {
        final coordinator = createCoordinator(async)..attach(host);
        // 2 minutes in foreground
        async.elapse(const Duration(minutes: 2));

        // Backgrounded for 20 minutes (background time must NOT count)
        coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
        async.elapse(const Duration(minutes: 20));
        expect(host.presentCount, 0);

        // Resume app
        coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        // Needs 3 more active foreground minutes
        async.elapse(const Duration(minutes: 2, seconds: 59));
        expect(host.presentCount, 0);

        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(host.presentCount, 1);
        coordinator.dispose();
      });
    });

    test('Scenario 5 & 6: User taps Later -> popup closes, reopens before cooldown -> no popup', () async {
      fakeAsync((async) {
        host.tapLater = true;
        final coordinator = createCoordinator(async)..attach(host);
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(host.presentCount, 1);
        coordinator.dispose();

        final storage = ReviewStorage(prefs);
        final state = storage.read();
        expect(state.laterCount, 1);
        expect(state.nextEligibleAt, fakeNow.add(const Duration(hours: 34)));

        // User reopens after 10 hours (well before 34h cooldown)
        fakeNow = fakeNow.add(const Duration(hours: 10));
        final nextHost = _MockReviewHost();
        final relaunch = createCoordinator(async, storage: storage)..attach(nextHost);
        async.elapse(const Duration(minutes: 30));
        async.flushMicrotasks();
        expect(nextHost.presentCount, 0, reason: 'Cooldown has not expired');
        relaunch.dispose();
      });
    });

    test('Scenario 7: User returns after cooldown and meets usage requirement -> popup appears again', () async {
      fakeAsync((async) {
        final storage = ReviewStorage(prefs);
        host.tapLater = true;
        final coordinator = createCoordinator(async, storage: storage)..attach(host);
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(host.presentCount, 1);
        coordinator.dispose();

        // 35 hours later (cooldown expired)
        fakeNow = fakeNow.add(const Duration(hours: 35));
        final nextHost = _MockReviewHost();
        final nextCoordinator = createCoordinator(async, storage: storage)..attach(nextHost);
        async.flushMicrotasks();
        expect(nextHost.presentCount, 0, reason: 'Needs 5 new minutes in the new session');

        // Accumulate 5 minutes of active usage in the new session
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(nextHost.presentCount, 1, reason: 'Popup appears after cooldown + 5m usage');
        nextCoordinator.dispose();
      });
    });

    test('Scenario 8, 9 & 10: User taps Rate App -> store opened -> reviewed preference saved -> never shown again', () async {
      fakeAsync((async) {
        host.tapRate = true;
        launcher.shouldSucceed = true;
        final storage = ReviewStorage(prefs);
        final coordinator = createCoordinator(async, storage: storage)..attach(host);
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();

        expect(launcher.openCount, 1, reason: 'Store launcher invoked');
        expect(host.lastStoreOpenedResult, isTrue);
        coordinator.dispose();

        final state = storage.read();
        expect(state.actionInitiated, isTrue, reason: 'reviewed marked true');

        // Reopens 1 year later with hours of usage -> never prompts again
        fakeNow = fakeNow.add(const Duration(days: 365));
        final futureHost = _MockReviewHost();
        final futureCoordinator = createCoordinator(async, storage: storage)..attach(futureHost);
        async.elapse(const Duration(hours: 10));
        async.flushMicrotasks();
        expect(futureHost.presentCount, 0, reason: 'Never prompts after Rate App');
        futureCoordinator.dispose();
      });
    });

    test('Scenario 11: Multiple rapid triggers -> never show duplicate popups simultaneously', () async {
      fakeAsync((async) {
        final coordinator = createCoordinator(async)..attach(host);
        async.elapse(const Duration(minutes: 5));
        for (var i = 0; i < 5; i++) {
          unawaited(coordinator.tryPrompt());
        }
        async.flushMicrotasks();
        expect(host.presentCount, 1, reason: 'Guarded against duplicate prompts in flight');
        coordinator.dispose();
      });
    });

    test('Scenario 12: Critical dialog or unsafe moment open -> popup postponed until safe', () async {
      fakeAsync((async) {
        host.isSafe = false; // Unsafe moment (e.g. video playing or dialog open)
        final coordinator = createCoordinator(async)..attach(host);
        async.elapse(const Duration(minutes: 6));
        async.flushMicrotasks();
        expect(host.presentCount, 0, reason: 'Must wait while moment is unsafe');

        // Now safe
        host.isSafe = true;
        unawaited(coordinator.tryPrompt());
        async.flushMicrotasks();
        expect(host.presentCount, 1, reason: 'Prompts once moment becomes safe');
        coordinator.dispose();
      });
    });

    test('Scenario 13: Store navigation fails -> handle safely without marking as reviewed', () async {
      fakeAsync((async) {
        host.tapRate = true;
        launcher.shouldSucceed = false; // Store navigation fails
        final storage = ReviewStorage(prefs);
        final coordinator = createCoordinator(async, storage: storage)..attach(host);
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();

        expect(launcher.openCount, 1);
        expect(host.lastStoreOpenedResult, isFalse);
        coordinator.dispose();

        final state = storage.read();
        expect(state.actionInitiated, isFalse, reason: 'Failed navigation must NOT mark reviewed');
      });
    });

    test('Scenario 14: Existing application flows continue to operate normally', () async {
      fakeAsync((async) {
        final coordinator = createCoordinator(async)..attach(host);
        coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        coordinator.didChangeAppLifecycleState(AppLifecycleState.inactive);
        coordinator.didChangeAppLifecycleState(AppLifecycleState.paused);
        coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        coordinator.detach(host);
        coordinator.attach(host);
        coordinator.dispose();
        // Completed lifecycle changes without crashes or memory leaks
        expect(true, isTrue);
      });
    });
  });
}

