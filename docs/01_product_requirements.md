# 01 — Product Requirements

## Vision

Pirith Potha is a digital Pirith Potha (chant book) for Sri Lankan Buddhist
users — not just "an MP3 player with Pirith." Content should be organized
around how people actually use it (morning, before sleep, daily, metta), and
the app should feel devotional and calm rather than like a generic media app.

## Audience & language

Primary audience: Sri Lankan users. **The entire app must be usable end-to-end
in Sinhala**, with English as the second supported language (see
[`08_ui_ux.md`](08_ui_ux.md) for the localization mechanism). Every user-facing
string — navigation, buttons, error messages, empty states, settings — ships
in both languages from the first release, not just chant titles.

## MVP scope (V1.0)

- Home (search, featured, popular, categories, recently played, downloaded)
- Pirith catalogue with categories and search
- Pirith details screen (cover, title in Sinhala + English, duration, play,
  download, favorite)
- Audio playback: play/pause/seek/next/previous
- Background playback + lock-screen playback + notification controls +
  Bluetooth/headset controls
- Offline download + offline playback
- Favorites
- Guest mode (no forced account creation to listen)
- Google Sign-In + Apple Sign-In
- AdMob banner ads (non-intrusive placement)
- Firebase Analytics + Crashlytics
- Settings screen
- Full Sinhala + English UI

## V1.1 scope

- Sleep timer
- Recently played (dedicated section/history)
- Playlists
- Improved search

## V2 scope — Premium

- Remove ads
- Premium-only Pirith content
- Unlimited downloads
- Higher audio quality
- Exclusive collections
- Server-verified subscription billing (Google Play Billing / Apple StoreKit)

## Screens (MVP)

1. Splash
2. Home
3. Pirith details
4. Full-screen player (+ persistent mini-player)
5. Downloads
6. Favorites
7. Profile (auth state, settings, premium entry point)

## Non-goals for MVP

- Real payments/subscriptions (architecture is prepared in Phase 9, billing
  is not implemented until after MVP has real users)
- Admin panel (needed eventually for content management, but not part of the
  mobile app phases — tracked separately)
- Algolia/Meilisearch-grade search (start with Firestore/local search; revisit
  only if the catalogue grows large)
