# 07 — Monetization

## AdMob (MVP)

- `google_mobile_ads`, wrapped behind an `AdService` abstraction — UI never
  calls the AdMob SDK directly.
- Banner ads only for MVP.
- Placement: below/within content lists (e.g. home feed), never overlaid on
  or adjacent to the audio player screen. This is a devotional app; ads must
  not feel intrusive on the core listening experience.
- Use AdMob test ad unit IDs during development; production IDs come from a
  single configurable location (not hardcoded across multiple widgets).
- Architecture must allow disabling ads entirely when `isPremium == true`,
  even though Premium itself isn't implemented in the AdMob phase.

```
AdService (interface)
   ↓
AdRepository / AdManager (data layer)
   ↓
google_mobile_ads SDK
```

## Premium (V2 — architecture only until real users exist)

Potential premium capabilities: no ads, premium-only Pirith, unlimited
downloads, higher audio quality, exclusive collections, sleep timer, advanced
playlists, cloud sync.

### Entitlement architecture

```
PremiumBloc
   ↓
PremiumRepository (interface)
   ↓
Premium entitlement source (data layer)
```

A `Pirith.isPremium` flag (see [`03_database_schema.md`](03_database_schema.md))
gates content at the catalogue level. Feature access (ads-off, unlimited
downloads, etc.) should be checked through a single feature-access
abstraction (e.g. `PremiumRepository.hasAccess(Feature)`), not scattered
`if (user.isPremium)` checks across features.

### What NOT to do

- Do not implement Google Play Billing / Apple StoreKit until this is
  explicitly scoped as its own phase.
- Do not fake premium purchases or unlock premium via a purely client-side
  boolean for real paid entitlement — a client-writable Firestore field is
  acceptable as a placeholder during development but must not be the source
  of truth for actual paid subscriptions in production. Real entitlement
  needs server-side verification (Cloud Function validating a Play/App Store
  receipt) before this ships to paying users.

## Analytics events (to track once Analytics is added)

`pirith_played`, `pirith_downloaded`, `pirith_completed`, `favorite_added`,
`search_used`, `premium_clicked`. No unnecessary personal data collection.
