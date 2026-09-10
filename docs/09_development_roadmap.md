# 09 — Development Roadmap

Each phase below is scoped, planned, and approved **individually** — one at a
time, per the project workflow in [`CLAUDE.md`](../CLAUDE.md). A phase is not
started until the previous one has been implemented, analyzed, tested, and
reviewed.

```
Documentation (this docs/ set)               ← done
      ↓
Phase 1 — Flutter Foundation
      ↓
Phase 2 — Firebase
      ↓
Phase 3 — Authentication
      ↓
Phase 4 — Pirith Catalogue
      ↓
Phase 5 — Audio Player
      ↓
Phase 6 — Offline Download
      ↓
Phase 7 — Favorites / History
      ↓
Phase 8 — AdMob
      ↓
Phase 9 — Premium Architecture
      ↓
Phase 10 — Testing & Production Hardening
      ↓
Production release prep
```

## Phase 1 — Flutter Foundation

Feature-first Clean Architecture folder structure, BLoC setup, `get_it` DI,
`go_router`, core constants/error handling, theme (light/dark), l10n
scaffolding (Sinhala + English ARB files wired up even if only a couple of
strings exist yet), placeholder screens for each feature. No Firebase, audio,
downloads, AdMob, or Premium logic yet.

## Phase 2 — Firebase

Firebase Core/Auth/Firestore/Storage/Analytics/Crashlytics initialization and
data-layer abstractions (remote data sources, repository implementations,
error mapping). No full auth UI, audio, downloads, or Premium yet.

## Phase 3 — Authentication

Guest/anonymous, Google, Apple sign-in, account linking, `AuthBloc`, sign-out,
profile basics. See [`06_authentication.md`](06_authentication.md).

## Phase 4 — Pirith Catalogue

Pirith + category models, Firestore data source, repository, use cases,
`PirithBloc`/`HomeBloc`, Home screen, categories, search, details screen (no
real audio playback yet — placeholders for play/download/favorite buttons).

## Phase 5 — Audio Player

The centralized `AudioPlayerManager` (`just_audio` + `audio_service`),
`PlayerBloc`, mini-player + full player UI, background/lock-screen playback,
notification controls, Bluetooth/headset support. See
[`04_audio_architecture.md`](04_audio_architecture.md). Get this solid before
heavy UI polish elsewhere — it's the highest-risk phase.

## Phase 6 — Offline Download

`DownloadManager`, `DownloadBloc`, Downloads screen, offline playback
verified with network disabled. See
[`05_offline_download.md`](05_offline_download.md).

## Phase 7 — Favorites / History

Favorites and recently-played history, persisted locally via
`shared_preferences` (works fully offline for guest and signed-in users
alike). **Scope note:** Firestore sync for signed-in (non-anonymous) users
across devices, and the "safe merge on login" case this originally called
for, were deliberately deferred rather than built here — the
`FavoritesRepository`/`HistoryRepository` interfaces don't leak
local-vs-remote storage to callers, so adding sync later is a data-layer
change, not a redesign. Revisit as its own phase once cross-device sync is
actually needed.

## Phase 8 — AdMob

Banner ads via `AdService` abstraction, placement rules, architecture ready
to disable ads for Premium (no billing yet). See
[`07_monetization.md`](07_monetization.md).

## Phase 9 — Premium Architecture

`PremiumBloc`, `PremiumRepository`, entitlement model, feature-access
abstraction. No real billing integration yet — architecture only.
`PremiumRepository` watches `users/{uid}.isPremium` (read-only from the
app — nothing in the app ever writes it, so it stays a manually-set dev
placeholder per docs/07_monetization.md until real billing lands); AdMob's
`adsEnabled` and premium-Pirith gating (`ensurePremiumAccess`) both already
read through it, so wiring up real entitlement later is a data-layer
change under `PremiumRepositoryImpl`, not a redesign.

## Phase 10 — Testing & Production Hardening

Full audit against [`10_testing_checklist.md`](10_testing_checklist.md):
architecture conformance, error/loading/empty states, offline behavior,
Android/iOS lifecycle and permissions, `flutter analyze` clean, unit/BLoC
tests filled in, production-readiness report.

## After Phase 10

Play Store / App Store release prep (icons, splash, signing, build configs) —
scoped as its own step once the app is stable, with no production data or
identifier changes made without explicit confirmation.
