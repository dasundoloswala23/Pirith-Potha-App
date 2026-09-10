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
