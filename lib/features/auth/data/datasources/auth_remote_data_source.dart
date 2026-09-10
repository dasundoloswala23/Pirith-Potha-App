import 'package:firebase_auth/firebase_auth.dart' show User;

/// Raw Firebase Auth + provider SDK access. Returns firebase_auth's [User]
/// directly — only [AuthRepositoryImpl] (data/repositories) sees this type;
/// it maps to the domain [AppUser] before anything else touches it. See
/// docs/02_architecture.md.
abstract interface class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  Future<User> signInAnonymously();

  /// Signs in with Google, linking to the current anonymous session when
  /// one exists (see docs/06_authentication.md for why).
  Future<User> signInWithGoogle();

  /// Signs in with Apple, with the same guest-linking behavior.
  Future<User> signInWithApple();

  Future<void> signOut();
}
