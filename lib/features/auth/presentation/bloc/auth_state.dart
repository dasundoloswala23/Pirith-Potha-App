part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A sign-in action (Google/Apple) is in flight. The previous [Authenticated]
/// guest user is kept so the UI doesn't flash back to a signed-out look.
class AuthLoading extends AuthState {
  const AuthLoading(this.previousUser);

  final AppUser? previousUser;

  @override
  List<Object?> get props => [previousUser];
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AppUser user;

  bool get isGuest => user.isAnonymous;

  @override
  List<Object?> get props => [user];
}

/// No Firebase user at all yet (before the initial guest sign-in completes,
/// or right after a sign-out with no auto re-auth).
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.failure, this.previousUser);

  final Failure failure;
  final AppUser? previousUser;

  @override
  List<Object?> get props => [failure, previousUser];
}
