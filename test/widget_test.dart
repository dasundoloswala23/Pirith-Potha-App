import 'package:flutter_test/flutter_test.dart';

import 'package:pitithpotha/app/app.dart';
import 'package:pitithpotha/features/auth/domain/entities/app_user.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_out.dart';
import 'package:pitithpotha/features/auth/presentation/bloc/auth_bloc.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  testWidgets('App launches to the Home tab', (WidgetTester tester) async {
    final fakeRepository = FakeAuthRepository(
      initialUser: const AppUser(uid: 'guest-1', isAnonymous: true),
    );
    final authBloc = AuthBloc(
      authRepository: fakeRepository,
      signInAnonymously: SignInAnonymously(fakeRepository),
      signInWithGoogle: SignInWithGoogle(fakeRepository),
      signInWithApple: SignInWithApple(fakeRepository),
      signOut: SignOut(fakeRepository),
    );
    addTearDown(authBloc.close);

    await tester.pumpWidget(PirithPothaApp(authBloc: authBloc));
    await tester.pumpAndSettle();

    expect(find.byType(PirithPothaApp), findsOneWidget);
  });
}
