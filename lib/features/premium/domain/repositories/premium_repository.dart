import '../entities/premium_feature.dart';

/// Premium entitlement abstraction — see docs/07_monetization.md.
///
/// V1 scope: read-only, backed by a Firestore `users/{uid}.isPremium`
/// field that only server-side tooling (Cloud Function, admin console)
/// would ever set for a real paid user — this app never writes it. That
/// makes it a safe placeholder for development (docs explicitly allow a
/// client-writable-looking field as a stand-in *as long as nothing here
/// treats it as the real source of truth for paid entitlement). Real
/// billing (Google Play Billing / Apple StoreKit + server-side receipt
/// verification) is a future phase, not implemented here.
abstract interface class PremiumRepository {
  Stream<bool> get isPremiumStream;

  bool get isPremium;

  /// Single feature-access checkpoint every call site should use instead
  /// of inlining `if (isPremium)` — see docs/07_monetization.md on why.
  bool hasAccess(PremiumFeature feature);
}
