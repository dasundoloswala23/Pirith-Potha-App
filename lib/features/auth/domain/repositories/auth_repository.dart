import '../entities/app_user.dart';

/// Auth abstraction the domain/presentation layers depend on. The Firebase
/// implementation lives in the data layer — see
/// docs/06_authentication.md.
abstract interface class AuthRepository {
  /// Emits the current user (or null when signed out) whenever auth state
  /// changes. A freshly-installed app has no user until [signInAnonymously]
  /// is called.
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  /// Starts (or resumes) a guest session. This is the default session type
  /// — listening to free Pirith must never require a real account.
  Future<AppUser> signInAnonymously();

  /// Signs in with Google. If the current session is a guest session, the
  /// guest account is linked to the Google account instead of creating a
  /// new uid, so favorites/downloads/history made as a guest are preserved.
  Future<AppUser> signInWithGoogle();

  /// Signs in with Apple, with the same guest-linking behavior as
  /// [signInWithGoogle].
  Future<AppUser> signInWithApple();

  Future<void> signOut();
}
