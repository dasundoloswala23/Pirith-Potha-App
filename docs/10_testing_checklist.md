# 10 — Testing Checklist

## Definition of "done" for every phase

- `flutter analyze` runs clean (no new errors/warnings introduced).
- Relevant unit/BLoC tests pass; new business logic (use cases, BLoCs) gets
  test coverage where practical for that phase.
- Manual verification steps are provided and were actually followed for
  anything that can't be meaningfully unit-tested (audio playback,
  background/lock-screen behavior, downloads, ads).
- Architecture rules from [`CLAUDE.md`](../CLAUDE.md) /
  [`02_architecture.md`](02_architecture.md) are respected — no UI-layer code
  reaching into Firebase, `just_audio`, or the file system directly.
- Both Sinhala and English UI are checked for the screens touched in that
  phase (no hardcoded strings, no missing translations, Sinhala font renders
  correctly).

## Phase-specific manual checks

- **Phase 1**: app builds and launches to placeholder screens in both
  languages; routing between placeholder screens works.
- **Phase 2**: Firebase initializes without error on a real device/emulator;
  no secrets committed to source control.
- **Phase 3**: guest → Google/Apple sign-in → account linking preserves any
  local guest data; sign-out returns cleanly to guest state.
- **Phase 4**: catalogue loads from Firestore, search and category filters
  work, Sinhala/English titles display correctly.
- **Phase 5**: playback continues with app backgrounded and screen locked;
  notification/lock-screen controls work; Bluetooth/headset controls work;
  audio correctly pauses/resumes on interruption (e.g. incoming call).
- **Phase 6**: download completes, progress displays, downloaded item plays
  with airplane mode / no network enabled, delete removes file + record,
  interrupted download doesn't corrupt app state.
- **Phase 7**: guest favorites/history persist locally; merge correctly on
  sign-in without duplication.
- **Phase 8**: ads display correctly in test mode, never overlap the player,
  don't block core navigation.
- **Phase 9**: entitlement checks work off a manually-set Firestore flag in
  development; no real billing calls exist yet.
- **Phase 10**: full regression pass across all of the above plus empty
  states, error states (no network, Firebase errors, storage full), and
  memory/performance spot checks.

## Production hardening audit (Phase 10 / pre-release)

Architecture, BLoC state management, Firebase usage, auth, Firestore,
Storage, audio, background/lock-screen playback, downloads, offline mode,
favorites, history, AdMob, error handling, loading/empty states, network
failures, storage failures, app lifecycle, Android permissions, iOS
configuration, memory usage, performance — audited together and reported
before any release-prep step touches signing, identifiers, or store listings.

## Phase 10 audit results

Verified: `flutter analyze` clean (only pre-existing `prefer_initializing_formals`
info-level lints across the BLoCs — cosmetic, not fixed since the field
names intentionally differ from the DI-facing constructor parameter names),
`flutter test` 21/21 passing, `flutter build web --release` and
`flutter build apk --debug` both succeed.

### Fixed during this audit

- **Error states silently spun forever.** Every screen except Home checked
  only `is! CatalogueLoaded` and showed a permanent loading spinner on a
  real `CatalogueError` (Firestore/network failure) — no message, no
  retry. Extracted `CatalogueLoadedBuilder`/`CatalogueErrorView`
  (`features/pirith/presentation/widgets/catalogue_loaded_builder.dart`)
  and switched all 8 catalogue-reading screens (Home, Search, Categories,
  Category detail, Pirith details, Downloads, Favorites, Recently Played)
  to it, so a real error now shows a retry button everywhere instead of
  just on Home.
- **Downloads didn't actually work offline**, despite that being an
  explicit requirement (docs/05_offline_download.md). The catalogue itself
  was never cached locally — Phase 4 only fetched from Firestore — so with
  no network, `CatalogueBloc` stayed in `CatalogueError`/`CatalogueLoading`
  forever and the Downloads screen (which resolves titles by
  cross-referencing the catalogue) couldn't show anything, even though the
  downloaded audio files and `DownloadBloc` state were fully available
  locally. Added `PirithLocalDataSource` (shared_preferences-backed,
  same pattern as Favorites/History) and made `PirithRepositoryImpl`
  offline-first: cache the catalogue on every successful fetch, fall back
  to the cache on failure, only surface a real error when both the network
  call and the cache are empty (e.g. a genuinely first-ever offline
  launch). Covered by
  `test/features/pirith/pirith_repository_impl_test.dart`. This also means
  Home/Search/Favorites/Categories now work offline after the first
  successful load, not just Downloads.
- **Missing Firestore composite index.** `getActivePirith()`'s
  `where('isActive', ==, true).orderBy('sortOrder')` query requires a
  composite index that was never defined — without it, Firestore returns
  `FAILED_PRECONDITION` in production. Added `firestore.indexes.json`
  documenting it (not yet deployed — see below).
- **Android 13+ notification permission** (`POST_NOTIFICATIONS`) was
  missing from the manifest — required for the audio_service playback
  notification to appear on API 33+. Added the manifest declaration; see
  "Known gaps" below for what's still missing.
- **iOS Sign in with Apple entitlement** was never created — added
  `ios/Runner/Runner.entitlements` with `com.apple.developer.applesignin`,
  but it isn't wired into the Xcode project yet (see "Known gaps").

### Known gaps / follow-ups before a real release

- **Android 13+ notification permission is declared but not requested at
  runtime.** Audio still plays without it; the system notification (media
  controls, lock screen) just won't appear on API 33+ until the user grants
  it manually in system settings. A proper fix asks for the permission
  (e.g. on first play) — not implemented, since it needs a UX decision
  (when/how to prompt) beyond this audit's scope.
- **iOS Sign in with Apple capability isn't linked in Xcode yet.** The
  entitlements file exists but needs someone on a Mac to add the "Sign in
  with Apple" capability via Runner's Signing & Capabilities tab (which
  safely updates `project.pbxproj`) — hand-editing that file from outside
  Xcode risks corrupting it, so it wasn't attempted here.
- **`firestore.rules`, `storage.rules`, and `firestore.indexes.json` are
  not deployed.** They exist in the repo as reviewed source of truth (per
  Phase 2) but nothing has run `firebase deploy` — that's a
  production-affecting action requiring explicit confirmation when it's
  actually time to do it, not something to do proactively during an audit.
- **Cover art isn't loaded from `coverUrl`.** `PirithArtwork` always shows
  the generated placeholder (colored tile + dhamma mark), never the real
  Firestore `coverUrl` image, even when one exists. This was an accepted
  placeholder from Phase 4, not a regression — flagged here as a content
  polish item, not a correctness bug.
- **Downloads aren't resilient to the app being backgrounded/killed
  mid-transfer on Android.** Only audio playback runs as a foreground
  service; a long download can be suspended if the OS reclaims the app in
  the background. Acceptable for MVP (per docs/05_offline_download.md,
  pause/resume wasn't required either), but worth a foreground download
  service if downloads turn out to be slow/large in practice.
- **`prefer_initializing_formals` info-level lints** remain on every BLoC
  constructor (field names differ from the DI-facing parameter names on
  purpose, for readable call sites in `injection_container.dart`) —
  cosmetic, left as-is.

None of the above block continued development; they're the concrete list
to work through before an actual store submission (alongside the
not-yet-started Play Store/App Store release prep steps in
[`09_development_roadmap.md`](09_development_roadmap.md)).
