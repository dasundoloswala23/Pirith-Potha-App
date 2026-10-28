import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pitithpotha/core/l10n/app_localizations.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:pitithpotha/features/app_review/presentation/review_prompt_coordinator.dart';
import 'package:pitithpotha/features/app_review/presentation/widgets/review_invitation_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens the sheet from a button and returns a future for its outcome.
Future<Future<ReviewSheetOutcome>> _open(
  WidgetTester tester,
  Future<bool> Function() openStore,
) async {
  SharedPreferences.setMockInitialValues({});
  final language = LanguageCubit(await SharedPreferences.getInstance());
  addTearDown(language.close);

  late Future<ReviewSheetOutcome> outcome;
  await tester.pumpWidget(
    BlocProvider.value(
      value: language,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  outcome = showReviewInvitationSheet(context, openStore: openStore),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return outcome;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the invitation copy and both actions, no star rating '
      'input', (tester) async {
    await _open(tester, () async => true);

    expect(find.text('Enjoying your experience?'), findsOneWidget);
    expect(find.textContaining('Your feedback means a lot to us!'), findsOneWidget);
    expect(find.text('⭐ Rate App'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);
    // Decorative stars aren't tappable rating controls.
    expect(
      find.ancestor(of: find.byIcon(Icons.star_rounded), matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('Maybe Later closes as later', (tester) async {
    final outcome = await _open(tester, () async => true);
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();
    expect(await outcome, ReviewSheetOutcome.later);
    expect(find.byType(ReviewInvitationSheet), findsNothing);
  });

  testWidgets('swiping it away also counts as later', (tester) async {
    final outcome = await _open(tester, () async => true);
    await tester.tapAt(const Offset(10, 10)); // the barrier
    await tester.pumpAndSettle();
    expect(await outcome, ReviewSheetOutcome.later);
  });

  testWidgets('Rate: store opens → closes, thanks without claiming a review '
      'was posted', (tester) async {
    final outcome = await _open(tester, () async => true);
    await tester.tap(find.text('⭐ Rate App'));
    await tester.pumpAndSettle();

    expect(await outcome, ReviewSheetOutcome.storeOpened);
    expect(find.text('Thank you for your feedback!'), findsOneWidget);
  });

  testWidgets('Rate: store fails → stays open with an error', (tester) async {
    await _open(tester, () async => false);
    await tester.tap(find.text('⭐ Rate App'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewInvitationSheet), findsOneWidget);
    expect(find.text("Couldn't open the store. Please try again later."), findsOneWidget);
  });

  testWidgets('repeated taps while opening call the store once', (tester) async {
    var calls = 0;
    final gate = Completer<bool>();
    await _open(tester, () {
      calls++;
      return gate.future;
    });

    final rate = find.text('⭐ Rate App');
    await tester.tap(rate);
    await tester.pump();
    // The label is replaced by a spinner while in flight; tap the button area.
    await tester.tap(find.byType(CircularProgressIndicator), warnIfMissed: false);
    await tester.tap(find.byType(CircularProgressIndicator), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    gate.complete(true);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: shows fully without animating', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await _open(tester, () async => true);
    expect(find.text('Enjoying your experience?'), findsOneWidget);
  });
}
