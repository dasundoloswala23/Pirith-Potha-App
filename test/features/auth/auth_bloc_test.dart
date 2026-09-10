import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/auth/domain/entities/app_user.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_anonymously.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pitithpotha/features/auth/domain/usecases/sign_out.dart';
import 'package:pitithpotha/features/auth/presentation/bloc/auth_bloc.dart';

import '../../fakes/fake_auth_repository.dart';

AuthBloc _buildBloc(FakeAuthRepository repository) => AuthBloc(
      authRepository: repository,
      signInAnonymously: SignInAnonymously(repository),
      signInWithGoogle: SignInWithGoogle(repository),
      signInWithApple: SignInWithApple(repository),
      signOut: SignOut(repository),
    );

void main() {
  group('AuthBloc', () {
    test('starts a guest session when no user exists yet', () async {
      final repository = FakeAuthRepository();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);

      bloc.add(const AuthStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states, isNotEmpty);
      final last = states.last;
      expect(last, isA<Authenticated>());
      expect((last as Authenticated).isGuest, isTrue);
    });

    test('resumes an existing guest session without re-authenticating', () async {
      final repository = FakeAuthRepository(
        initialUser: const AppUser(uid: 'guest-42', isAnonymous: true),
      );
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await expectLater(
        bloc.stream,
        emits(isA<Authenticated>().having((s) => s.user.uid, 'uid', 'guest-42')),
      );
    });

    test('sign-in with Google transitions Loading then Authenticated', () async {
      final repository = FakeAuthRepository(
        initialUser: const AppUser(uid: 'guest-1', isAnonymous: true),
      );
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<Authenticated>().having((s) => s.isGuest, 'isGuest', isFalse),
        ]),
      );

      bloc.add(const AuthSignInWithGoogleRequested());
      await future;
    });

    test('sign-out returns to Unauthenticated', () async {
      final repository = FakeAuthRepository(
        initialUser: const AppUser(uid: 'guest-1', isAnonymous: true),
      );
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const AuthStarted());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final future = expectLater(bloc.stream, emits(isA<Unauthenticated>()));
      bloc.add(const AuthSignOutRequested());
      await future;
    });
  });
}
