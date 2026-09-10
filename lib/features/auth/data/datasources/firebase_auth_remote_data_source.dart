import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:sign_in_with_apple/sign_in_with_apple.dart' hide generateNonce;

import '../../../../core/utils/nonce_generator.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;
  final google.GoogleSignIn _googleSignIn = google.GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    return credential.user!;
  }

  @override
  Future<User> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError(
        'Interactive Google sign-in is not supported on this platform build '
        '(e.g. web needs the rendered Google button, not this flow).',
      );
    }

    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _signInOrLinkWithCredential(credential);
  }

  @override
  Future<User> signInWithApple() async {
    final rawNonce = generateNonce();
    final hashedNonce = sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: hashedNonce,
    );

    final credential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
    return _signInOrLinkWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (_googleSignInInitialized) {
      await _googleSignIn.signOut();
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  /// If the current session is a guest (anonymous) session, links the new
  /// credential to it so the guest's uid — and anything already saved under
  /// it — is preserved, rather than creating a brand-new account. Falls
  /// back to a plain sign-in when the credential already belongs to an
  /// existing account. See docs/06_authentication.md.
  Future<User> _signInOrLinkWithCredential(AuthCredential credential) async {
    final current = _firebaseAuth.currentUser;

    if (current != null && current.isAnonymous) {
      try {
        final result = await current.linkWithCredential(credential);
        return result.user!;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use' && e.code != 'email-already-in-use') {
          rethrow;
        }
        // Falls through to a plain sign-in below.
      }
    }

    final result = await _firebaseAuth.signInWithCredential(credential);
    return result.user!;
  }
}
