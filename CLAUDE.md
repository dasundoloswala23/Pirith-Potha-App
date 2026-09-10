# Pirith Potha — Project Instructions

You are the lead Flutter architect and senior mobile engineer for a production
mobile application called **Pirith Potha** (පිරිත් පොත).

## Project

Pirith Potha is a Buddhist devotional audio application focused primarily on
Sri Lankan users. Users discover, search, play, and download Pirith audio, and
listen to it offline. Audio must keep playing when the app is backgrounded or
the phone screen is locked.

**The interface is in English; Sinhala is reserved for Pirith content** (chant
names and descriptions, which come from Firestore). The Sinhala ARB file is
kept complete and in sync so a language switch stays a locale change rather
than a UI rewrite. See [`docs/08_ui_ux.md`](docs/08_ui_ux.md) for the
localization approach.

## Technology

- Flutter / Dart
- flutter_bloc (BLoC / Cubit)
- Clean Architecture + Repository Pattern
- get_it for dependency injection
- go_router
- Firebase: Auth, Cloud Firestore, Storage, Analytics, Crashlytics
- google_sign_in, sign_in_with_apple
- just_audio + audio_service
- Hive or Isar for local metadata/cache
- path_provider for local audio file storage
- google_mobile_ads (AdMob)
- flutter_localizations + intl (Sinhala + English)

## Architecture rules

Feature-first Clean Architecture under `lib/features/<feature>/{data,domain,presentation}`.

1. UI must never directly access Firebase, Firestore, or Storage.
2. UI must never directly access `just_audio` / `audio_service`.
3. BLoCs/Cubits coordinate presentation state only.
4. Repositories abstract all external services (remote + local data sources).
5. Use cases hold business logic between BLoCs and repositories.
6. Firebase implementations live in the data layer.
7. Local database/cache implementations live in the data layer.
8. Audio playback is centralized behind a single `AudioPlayerManager`/service —
   never instantiate player logic inside widgets.
9. Downloads are centralized behind a single `DownloadManager`.
10. Keep the app testable; avoid unnecessary dependencies.
11. Do not introduce a new architecture without discussing it first.
12. Do not rewrite existing working features unnecessarily.

## Product scope

Full eventual feature set (see [`docs/01_product_requirements.md`](docs/01_product_requirements.md)
for MVP vs. future split): Home, Pirith catalogue, categories, search, Pirith
details, cover images, audio playback, background/lock-screen playback,
notification + Bluetooth media controls, downloads with offline playback,
favorites, recently played, Google/Apple/guest auth, AdMob banner and
interstitial ads, Premium content and subscriptions (later), sleep timer,
playlists, analytics, crash reporting — English UI throughout, with Sinhala
Pirith content.

## Workflow — build one phase at a time

Development is **incremental**. Do not implement multiple phases in one pass.

Before modifying code:
1. Read the relevant files under `docs/` for the phase being worked on.
2. Inspect the existing project — current architecture, dependencies, Firebase
   config, existing files. Avoid duplicate implementations.
3. Explain what you plan to change, then implement only the requested phase.

After implementation:
1. Run `flutter analyze`.
2. Run relevant tests.
3. Fix errors.
4. Verify the change matches the architecture rules above.
5. Summarize changed files.
6. Explain how to manually test the feature.
7. **Do not move to the next phase automatically** — stop and wait for review.

The phase sequence is documented in
[`docs/09_development_roadmap.md`](docs/09_development_roadmap.md). If
requirements conflict between docs, stop and explain the conflict instead of
silently choosing.

The goal is a maintainable production-quality application, not a quick prototype.
