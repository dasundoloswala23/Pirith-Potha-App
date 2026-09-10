import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show AuthorizationErrorCode, SignInWithAppleAuthorizationException;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../core/errors/sign_in_cancelled_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> get authStateChanges =>
      _remoteDataSource.authStateChanges.map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_remoteDataSource.currentUser);

  @override
  Future<AppUser> signInAnonymously() =>
      _run(() => _remoteDataSource.signInAnonymously());

  @override
  Future<AppUser> signInWithGoogle() =>
      _run(() => _remoteDataSource.signInWithGoogle());

  @override
  Future<AppUser> signInWithApple() =>
      _run(() => _remoteDataSource.signInWithApple());

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
      throw AppException(mapFirebaseError(e));
    }
  }

  Future<AppUser> _run(Future<firebase.User> Function() action) async {
    try {
      final user = await action();
      return _toAppUser(user)!;
    } catch (e) {
      if (_isUserCancellation(e)) throw const SignInCancelledException();
      throw AppException(mapFirebaseError(e));
    }
  }

  bool _isUserCancellation(Object error) {
    if (error is GoogleSignInException) {
      return error.code == GoogleSignInExceptionCode.canceled;
    }
    if (error is SignInWithAppleAuthorizationException) {
      return error.code == AuthorizationErrorCode.canceled;
    }
    return false;
  }

  AppUser? _toAppUser(firebase.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }
}
