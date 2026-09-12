# Release checklist — Play Store & App Store

Status as of 11 September 2026. Items marked **BLOCKER** stop a submission.

## Android — done in the repo

| Item | State |
|---|---|
| App name shown under the launcher icon | `Pirith Potha` (was `pitithpotha`) |
| Adaptive launcher icon | Regenerated at 60% inside the safe zone; the default Android Studio green-grid background replaced with `#0E1A06` |
| Upload keystore | `android/keystore/pirith-potha-upload.p12`, PKCS12, RSA 2048, valid to 2054 |
| Release signing | `android/app/build.gradle.kts` reads `android/key.properties`; falls back to debug signing **with a build warning** when absent |
| Keystore in version control | Excluded — `android/.gitignore` covers `key.properties`, `*.p12`, `*.jks`, `/keystore/` |
| R8 / resource shrinking | Enabled, with keep rules in `android/app/proguard-rules.pro` |
| POST_NOTIFICATIONS runtime request | Implemented; asked at first playback, once per session |
| Release build verified on device | `ZL8325W28X` — launches, plays audio, media notification with transport controls appears |

### The keystore is irreplaceable

Google Play ties the app listing to the upload key's certificate. If
`pirith-potha-upload.p12` or its password is lost, **this app can never be
updated again** under the same listing — a new package name and a new listing
is the only recovery. Back up the `.p12` file and `android/key.properties`
somewhere durable and private (password manager, encrypted backup). Neither
file is in git, by design.

Certificate fingerprint of the current upload key:

```
SHA1:   D6:CD:24:CB:2E:B9:4D:B1:40:65:01:EF:18:FD:99:5E:6D:8F:2C:62
SHA256: 56:2D:AB:99:1B:42:E9:76:26:46:BA:6E:B4:93:06:B1:ED:CF:CC:12:DE:7D:E6:43:4A:07:C0:E8:A2:46:E0:AC
```

If you add Google Sign-In later, that SHA1 must be registered in the Firebase
console, or sign-in will fail in release builds only.

### Why minification needed keep rules

Turning on R8 broke the release build outright: the app died at launch with
`Failed to create an instance of androidx.work.impl.WorkDatabase`. Room
instantiates its generated `*_Impl` class by name, so R8 saw no reference and
stripped it. Nothing in `flutter analyze` or the test suite catches this — it
only appears in a minified build on a device. If you ever add a plugin that
uses reflection, re-run the release smoke test below rather than trusting a
green test run.

### Release smoke test (run before every submission)

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Then on the device: launch, play a chant, confirm the notification appears with
working controls, lock the screen and confirm audio continues, download a chant
and play it in airplane mode.

### Build the upload artifact

```bash
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab
```

## Android — needs your Play Console account

- [ ] **BLOCKER** Create the app in Play Console under package `com.pirith.pitithpotha`.
- [ ] **BLOCKER** Privacy policy URL in the listing (see below).
- [ ] **BLOCKER** Complete the Data safety form. Declare: anonymous app ID,
      usage/analytics, crash logs, advertising ID. Nothing is "collected" that
      identifies a person; favourites/playlists/history/downloads are local-only
      and must **not** be declared as collected.
- [ ] **BLOCKER** Ads declaration: yes, the app contains ads.
- [ ] Content rating questionnaire.
- [ ] Target audience: general, not children.
- [ ] Store listing text, screenshots (`store/` has icon and feature graphic).

## iOS — prepared in the repo

| Item | State |
|---|---|
| Display name | `Pirith Potha` (`CFBundleDisplayName` and `CFBundleName`) |
| App icons | Regenerated, 46 sizes, dark ground, **no alpha channel** (App Store rejects alpha) |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` — declares UserDefaults, file timestamp, disk space and boot time reasons plus collected data types |
| Export compliance | `ITSAppUsesNonExemptEncryption = false`, so App Store Connect stops asking on every upload |
| Background audio | `UIBackgroundModes: audio` already present |

## iOS — BLOCKERS that cannot be resolved from this machine

1. **A Mac is required.** iOS apps cannot be archived, signed or uploaded from
   Windows. Everything below needs macOS with Xcode, or a hosted Mac CI runner.
2. **`ios/Runner/GoogleService-Info.plist` is missing.** No iOS app exists in
   the Firebase project. Firebase will fail at startup on iOS until you register
   an iOS app with bundle ID `com.pirith.pitithpotha` and add that file.
3. **AdMob iOS is not configured.** `ios/Runner/Info.plist` still carries
   Google's public *test* `GADApplicationIdentifier`, and the three iOS slots in
   `lib/core/constants/ad_unit_ids.dart` are empty, so iOS deliberately serves
   test ads. Register the iOS app in AdMob, then fill in both places. Shipping
   with the test ID means no revenue; shipping production units against a test
   app ID means no fill.
4. **`PrivacyInfo.xcprivacy` must be added to the Runner target** in Xcode
   (Build Phases → Copy Bundle Resources). A file sitting in the folder is not
   bundled.
5. Apple Developer Program membership, certificates and provisioning profiles.

## Both stores

- [ ] **BLOCKER** Privacy policy must be publicly reachable. Draft is at
      `store/privacy-policy.html`; the contact email is a placeholder and must be
      filled in before publishing.
- [ ] Version for first release is `1.0.0+1` in `pubspec.yaml`. Increment the
      build number (`+N`) on every upload — both stores reject a duplicate.

## Known gaps, deliberately not fixed

- **Dark mode** is listed in Settings as "Coming soon" but is not implemented,
  while `AppTheme.dark` exists and the OS theme is followed. The setting row is
  inert; either implement the override or remove the row before release so the
  listing does not promise something that does nothing.
- **Audio quality**, **auto-download on Wi-Fi** and **storage used** are also
  "Coming soon" rows. Reviewers occasionally flag non-functional UI.
- **Google / Apple sign-in** use cases exist in the codebase but no screen
  triggers them; the app always runs as an anonymous guest. Apple requires
  Sign in with Apple only if you offer another third-party sign-in, so this is
  safe as long as sign-in stays unreachable.
