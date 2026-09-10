import 'dart:async';

import 'package:pitithpotha/features/auth/domain/entities/app_user.dart';
import 'package:pitithpotha/features/auth/domain/repositories/auth_repository.dart';

/// In-memory [AuthRepository] fake for widget/BLoC tests, so tests don't
/// need a live Firebase connection to exercise [AuthBloc].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _user = initialUser {
    _controller = StreamController<AppUser?>.broadcast(
      onListen: () {
        if (_user != null) scheduleMicrotask(() => _controller.add(_user));
      },
    );
  }

  AppUser? _user;
  late final StreamController<AppUser?> _controller;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInAnonymously() async {
    _user ??= const AppUser(uid: 'guest-1', isAnonymous: true);
    return _user!;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    _user = const AppUser(uid: 'google-user-1', isAnonymous: false, email: 'test@example.com');
    return _user!;
  }

  @override
  Future<AppUser> signInWithApple() async {
    _user = const AppUser(uid: 'apple-user-1', isAnonymous: false, email: 'test@example.com');
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}
