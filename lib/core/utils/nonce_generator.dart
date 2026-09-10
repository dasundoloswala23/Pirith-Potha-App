import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates the raw/hashed nonce pair Apple Sign In requires as a replay
/// protection: the hashed nonce is sent to Apple, the raw nonce is sent to
/// Firebase alongside Apple's returned identity token so Firebase can verify
/// it matches. See docs/06_authentication.md.
String generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String sha256ofString(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}
