/// Gated capabilities — see docs/07_monetization.md. V1 has no tiered
/// entitlement (every feature maps to the same `isPremium` flag via
/// [PremiumRepository.hasAccess]), but call sites already ask for the
/// specific feature they need so introducing real tiers later doesn't
/// require touching every call site.
enum PremiumFeature {
  adsRemoved,
  premiumContent,
  unlimitedDownloads,
  higherAudioQuality,
  exclusiveCollections,
  sleepTimer,
  advancedPlaylists,
  cloudSync,
}
