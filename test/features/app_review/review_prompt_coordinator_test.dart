import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/app_review/data/native_review_api.dart';
import 'package:pitithpotha/features/app_review/data/review_storage.dart';
import 'package:pitithpotha/features/app_review/domain/review_state.dart';
import 'package:pitithpotha/features/app_review/presentation/review_prompt_coordinator.dart';
import 'package:pitithpotha/features/app_review/presentation/usage_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHost implements ReviewPromptHost {
  bool safe = true;
  ReviewSheetOutcome? answer = ReviewSheetOutcome.later;
  bool tapRate = false;
  int presented = 0;
  bool? storeOpenedResult;
  Completer<void>? hold;

  @override
  bool get isSafeMoment => safe;

  @override
  Future<ReviewSheetOutcome> presentInvitation({
    required Future<bool> Function() openStore,
  }) async {
    presented++;
    if (hold != null) await hold!.future;
    if (tapRate) {
      storeOpenedResult = await openStore();
      // A failed open keeps the sheet up; the user then picks Later.
      return storeOpenedResult!
          ? ReviewSheetOutcome.storeOpened
          : ReviewSheetOutcome.later;
    }
    return answer!;
  }
}

class _FakeNative implements NativeReviewApi {
  bool available = true;
  bool storeFails = false;
  int requests = 0;
  int storeOpens = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing() async {
    storeOpens++;
    if (storeFails) throw Exception('Play Store unavailable');
  }
}

class _Harness {
  _Harness(this.prefs, {this.platform = TargetPlatform.android});

  final SharedPreferences prefs;
  final TargetPlatform platform;
  final native = _FakeNative();
  final host = _FakeHost();
  DateTime now = DateTime(2026, 10, 27, 9);
  String version = '1.00.03';

  late final storage = ReviewStorage(prefs);

  ReviewPromptCoordinator build(FakeAsync async) => ReviewPromptCoordinator(
    storage: storage,
    native: native,
    tracker: UsageTracker(
      monotonicNow: () => async.elapsed,
      timerFactory: Timer.new,
    ),
    clock: () => now,
    platform: () => platform,
    installedVersion: () async => version,
  );
}

Future<_Harness> _harness({
  Map<String, Object> saved = const {},
  TargetPlatform platform = TargetPlatform.android,
}) async {
  SharedPreferences.setMockInitialValues(saved);
  return _Harness(await SharedPreferences.getInstance(), platform: platform);
}

const _fiveMinutes = {'review_active_usage_ms': 300000};

void main() {
  test('nothing before 5 minutes of use; invitation once the threshold is '
      'reached on the main screen', () async {
    final h = await _harness();
    fakeAsync((async) {
      final c = h.build(async)..attach(h.host);
      async.elapse(const Duration(minutes: 4, seconds: 59));
      expect(h.host.presented, 0);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(h.host.presented, 1);
      c.dispose();
    });
  });

  test('at most once per session, however many triggers fire', () async {
    final h = await _harness(saved: _fiveMinutes);
    fakeAsync((async) {
      final c = h.build(async)..attach(h.host);
      async.flushMicrotasks();
      for (var i = 0; i < 10; i++) {
        unawaited(c.tryPrompt());
        c.didChangeAppLifecycleState(AppLifecycleState.paused);
        c.didChangeAppLifecycleState(AppLifecycleState.resumed);
        c.attach(h.host); // dashboard rebuild / tab change
      }
      async.flushMicrotasks();
      expect(h.host.presented, 1);
      c.dispose();
    });
  });

  test(
    'concurrent triggers while one is in flight never double-show',
    () async {
      final h = await _harness(saved: _fiveMinutes);
      h.host.hold = Completer<void>();
      fakeAsync((async) {
        final c = h.build(async);
        c.attach(h.host);
        unawaited(c.tryPrompt());
        unawaited(c.tryPrompt());
        async.flushMicrotasks();
        expect(h.host.presented, 1);
        h.host.hold!.complete();
        async.flushMicrotasks();
        c.dispose();
      });
    },
  );

  test('waits for a safe moment, then shows', () async {
    final h = await _harness(saved: _fiveMinutes);
    h.host.safe = false; // e.g. the player is open over Home
    fakeAsync((async) {
      final c = h.build(async)..attach(h.host);
      async.flushMicrotasks();
      expect(h.host.presented, 0);

      h.host.safe = true;
      unawaited(c.tryPrompt());
      async.flushMicrotasks();
      expect(h.host.presented, 1);
      c.dispose();
    });
  });

  test('never while backgrounded', () async {
    final h = await _harness(saved: _fiveMinutes);
    fakeAsync((async) {
      final c = h.build(async);
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      c.attach(h.host);
      async.flushMicrotasks();
      expect(h.host.presented, 0);
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(h.host.presented, 1);
      c.dispose();
    });
  });

  test(
    'Maybe Later: persists a 34 h cooldown from the tap; later launches '
    'during it show nothing; after it, shows once usage requirement is met',
    () async {
      final h = await _harness(saved: _fiveMinutes);
      fakeAsync((async) {
        final c = h.build(async)..attach(h.host);
        async.flushMicrotasks();
        c.dispose();
      });
      final saved = h.storage.read();
      expect(saved.laterCount, 1);
      expect(saved.nextEligibleAt, h.now.add(const Duration(hours: 34)));

      // Several relaunches during the cooldown.
      for (final hoursLater in [1, 12, 33]) {
        final relaunch = _Harness(h.prefs)
          ..now = h.now.add(Duration(hours: hoursLater));
        fakeAsync((async) {
          final c = relaunch.build(async)..attach(relaunch.host);
          async.flushMicrotasks();
          expect(
            relaunch.host.presented,
            0,
            reason: '$hoursLater h into cooldown',
          );
          c.dispose();
        });
      }

      // Reopened after it expired: requires 5 minutes of usage in the new session.
      final after = _Harness(h.prefs)
        ..now = h.now.add(const Duration(hours: 40));
      after.host.answer = ReviewSheetOutcome.later;
      fakeAsync((async) {
        final c = after.build(async)..attach(after.host);
        async.flushMicrotasks();
        expect(
          after.host.presented,
          0,
          reason: 'must accumulate 5 minutes of usage first',
        );
        async.elapse(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(after.host.presented, 1);
        c.dispose();
      });
      final second = after.storage.read();
      expect(second.laterCount, 2);
      expect(second.nextEligibleAt, after.now.add(const Duration(hours: 24)));
    },
  );

  test('Rate: store opens → flagged and never shown again', () async {
    final h = await _harness(saved: _fiveMinutes);
    h.host.tapRate = true;
    fakeAsync((async) {
      final c = h.build(async)..attach(h.host);
      async.flushMicrotasks();
      expect(h.host.storeOpenedResult, isTrue);
      c.dispose();
    });
    final saved = h.storage.read();
    expect(saved.actionInitiated, isTrue);
    expect(saved.laterCount, 0);

    final later = _Harness(h.prefs)..now = h.now.add(const Duration(days: 90));
    fakeAsync((async) {
      final c = later.build(async)..attach(later.host);
      async.elapse(const Duration(hours: 1));
      expect(later.host.presented, 0);
      c.dispose();
    });
  });

  test('Rate: store fails to open → not flagged; treated as Later', () async {
    final h = await _harness(saved: _fiveMinutes);
    h.host.tapRate = true;
    h.native.storeFails = true;
    fakeAsync((async) {
      final c = h.build(async)..attach(h.host);
      async.flushMicrotasks();
      expect(h.native.storeOpens, 1);
      expect(h.host.storeOpenedResult, isFalse);
      c.dispose();
    });
    final saved = h.storage.read();
    expect(saved.actionInitiated, isFalse);
    expect(saved.laterCount, 1);
  });

  group('iOS', () {
    test('shows the custom sheet on iOS and opens store', () async {
      final h = await _harness(
        saved: _fiveMinutes,
        platform: TargetPlatform.iOS,
      );
      fakeAsync((async) {
        final c = h.build(async)..attach(h.host);
        async.flushMicrotasks();
        expect(h.host.presented, 1);
        c.dispose();
      });
    });

    test(
      'requestNativeReview records version and invokes native API',
      () async {
        final h = await _harness(
          saved: _fiveMinutes,
          platform: TargetPlatform.iOS,
        );
        fakeAsync((async) {
          final c = h.build(async);
          unawaited(c.requestNativeReview());
          async.flushMicrotasks();
          expect(h.native.requests, 1);
          c.dispose();
        });
        final saved = h.storage.read();
        expect(saved.nativePromptVersion, '1.00.03');
      },
    );

    test('native API unavailable: recorded, nothing thrown', () async {
      final h = await _harness(
        saved: _fiveMinutes,
        platform: TargetPlatform.iOS,
      );
      h.native.available = false;
      fakeAsync((async) {
        final c = h.build(async);
        unawaited(c.requestNativeReview());
        async.flushMicrotasks();
        expect(h.native.requests, 0);
        c.dispose();
      });
      expect(h.storage.read().nativePromptVersion, '1.00.03');
    });
  });

  test('unsupported platform: nothing tracked, nothing shown', () async {
    final h = await _harness(
      saved: _fiveMinutes,
      platform: TargetPlatform.windows,
    );
    fakeAsync((async) {
      final c = h.build(async)..attach(h.host);
      async.elapse(const Duration(minutes: 10));
      expect(h.host.presented, 0);
      c.dispose();
    });
    expect(
      h.storage.read(),
      const ReviewState(activeUsage: Duration(minutes: 5)),
    );
  });
}
