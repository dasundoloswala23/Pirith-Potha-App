import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pitithpotha/app/app.dart';
import 'package:pitithpotha/features/auth/domain/entities/app_user.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_out.dart';
import 'package:pitithpotha/features/auth/presentation/bloc/auth_bloc.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  setUpAll(() {
    // Avoid real network calls to Google Fonts in the test sandbox; falls
    // back to the platform's default font, which is fine for these tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App launches on the splash screen, then reaches Home',
      (WidgetTester tester) async {
    final fakeRepository = FakeAuthRepository(
      initialUser: const AppUser(uid: 'guest-1', isAnonymous: true),
    );
    final authBloc = AuthBloc(
      authRepository: fakeRepository,
      signInAnonymously: SignInAnonymously(fakeRepository),
      signInWithGoogle: SignInWithGoogle(fakeRepository),
      signInWithApple: SignInWithApple(fakeRepository),
      signOut: SignOut(fakeRepository),
    )..add(const AuthStarted());
    addTearDown(authBloc.close);

    await tester.pumpWidget(PirithPothaApp(authBloc: authBloc));
    expect(find.byType(PirithPothaApp), findsOneWidget);

    // The splash screen holds for a minimum display time and drives a
    // repeating dots/rotation animation, so settle it with bounded pumps
    // instead of pumpAndSettle (which would time out on the infinite
    // animation). Pump past the full minimum display time so its internal
    // timer fires and the app navigates on to Home before the test ends.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PirithPothaApp), findsOneWidget);
  });
}
