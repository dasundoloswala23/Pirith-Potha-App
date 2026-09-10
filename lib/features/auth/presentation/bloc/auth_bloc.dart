import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/sign_in_cancelled_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// App-scoped BLoC (one instance for the whole app, registered as a
/// singleton in injection_container.dart) driving guest/Google/Apple auth.
/// See docs/06_authentication.md.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required SignInAnonymously signInAnonymously,
    required SignInWithGoogle signInWithGoogle,
    required SignInWithApple signInWithApple,
    required SignOut signOut,
  })  : _authRepository = authRepository,
        _signInAnonymously = signInAnonymously,
        _signInWithGoogle = signInWithGoogle,
        _signInWithApple = signInWithApple,
        _signOut = signOut,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthSignInWithAppleRequested>(_onSignInWithAppleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;
  final SignInAnonymously _signInAnonymously;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;
  final SignOut _signOut;

  StreamSubscription<AppUser?>? _authSubscription;

  AppUser? get _currentUserFromState => switch (state) {
        Authenticated(:final user) => user,
        AuthLoading(:final previousUser) => previousUser,
        AuthError(:final previousUser) => previousUser,
        _ => null,
      };

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );

    if (_authRepository.currentUser == null) {
      // No session at all yet — establish a guest session by default so
      // listening never requires an account. See docs/01_product_requirements.md.
      try {
        await _signInAnonymously();
      } catch (e) {
        emit(AuthError(_toFailure(e), null));
      }
    }
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(event.user == null ? const Unauthenticated() : Authenticated(event.user!));
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _attemptSignIn(emit, _signInWithGoogle.call);
  }

  Future<void> _onSignInWithAppleRequested(
    AuthSignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _attemptSignIn(emit, _signInWithApple.call);
  }

  Future<void> _attemptSignIn(
    Emitter<AuthState> emit,
    Future<AppUser> Function() signIn,
  ) async {
    final previousUser = _currentUserFromState;
    emit(AuthLoading(previousUser));
    try {
      final user = await signIn();
      emit(Authenticated(user));
    } on SignInCancelledException {
      // User dismissed the sheet — return to whatever state they were in.
      emit(previousUser == null ? const Unauthenticated() : Authenticated(previousUser));
    } catch (e) {
      emit(AuthError(_toFailure(e), previousUser));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _signOut();
      // authStateChanges will emit null and re-trigger a guest session via
      // the app's own listener if the UI re-dispatches AuthStarted; for now
      // just reflect the signed-out Firebase state.
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(_toFailure(e), _currentUserFromState));
    }
  }

  Failure _toFailure(Object error) =>
      error is AppException ? error.failure : const UnknownFailure();

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
