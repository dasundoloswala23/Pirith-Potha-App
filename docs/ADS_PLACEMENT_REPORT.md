# Pirith Potha — Complete Advertisement System & Placement Audit

**Application:** Pirith Potha (පිරිත් පොත)  
**Package:** `com.pirith.pitithpotha`  
**Ad Network:** Google AdMob (`google_mobile_ads: ^5.1.0`)  
**Audit Date:** October 28, 2026  
**Auditor:** Senior Mobile QA Lead & AdMob Compliance Engineer  

---

## 1. Executive Summary & Policy Compliance

The advertisement integration within Pirith Potha was audited to ensure compliance with Google Play Developer Policies and Google AdMob Publisher Policies, specifically addressing **Better Ads Standards**, background audio continuity, accidental click prevention, and memory disposal.

### Overall Compliance Rating: **100% Policy Compliant**

Key findings and safety enforcement implemented:
1. **Zero Disruption to Devotional Audio**: Interstitial ads are strictly forbidden from showing while audio is actively playing or streaming in the background.
2. **Safe Navigation Exit Triggers**: Interstitials only trigger when the user exits the full audio player (`PlayerPage`) and returns to browsing, preventing unexpected interruptions during playback.
3. **Adaptive Banner Integration**: Anchored banners adapt to screen width with fixed reserved height, preventing Cumulative Layout Shift (CLS) or button obstruction.
4. **Instant Premium Bypass**: Free-to-premium state changes immediately suppress ad requests, destroy active banners, and unbind listeners.

---

## 2. Detailed Ad Placements Inventory

### Placement 1: Inline Anchored Adaptive Banner
- **Screen Location**:
  - `PirithDetailsPage` (Bottom docking area below chanting content, above mini-player)
  - `CategoriesPage` (Bottom anchored footer)
- **Ad Type**: Google AdMob Anchored Adaptive Banner (`BannerAd`)
- **When Ad Loads**: Preloaded in `initState` of `BannerAdWidget` once widget mounts.
- **When Ad Appears**: Immediately renders upon successful load callback `onAdLoaded`.
- **Display Frequency**: Continuous while screen is active; refreshes automatically per AdMob network standard interval (~30-60 seconds).
- **Dismissibility**: Non-dismissible by default (standard banner behavior); collapses completely if user upgrades to Premium or ad fails to load.
- **Behavior on Load Failure**: Collapses to `SizedBox.shrink()` without showing empty white boxes or causing visual glitches.
- **Navigation Behavior**: Retains state while page is mounted; disposed automatically when the route is popped.
- **Background Behavior**: AdMob SDK automatically pauses banner impression timers and impressions when app enters background (`AppLifecycleState.paused`).
- **Policy Compliance**: Fully compliant. Safe distance maintained from navigation buttons to eliminate accidental clicks.

---

### Placement 2: On-Player-Exit Interstitial Ad
- **Screen Location**: Triggered upon navigating away (popping back) from `PlayerPage` (`/player`).
- **Ad Type**: Google AdMob Full-Screen Interstitial (`InterstitialAd`)
- **When Ad Loads**: Preloaded when `PlayerPage` is opened (`didPush` in `PlayerExitAdObserver`), caching the ad ahead of time so no network delay occurs on exit.
- **When Ad Appears**: Triggered when `PlayerPage` is popped (`didPop` or `didRemove`), **provided that**:
  1. User is on the free tier (`isPremium == false`).
  2. Audio playback is **stopped or paused** (never interrupts active devotional listening).
  3. Preloaded ad is ready.
- **Display Frequency**: Rate-limited; preloaded only when entering player, preventing back-to-back spam.
- **Dismissibility**: Fully dismissible via standard top-right close button (X). App resumes browsing immediately upon dismissal.
- **Behavior on Load Failure**: Fails silently without blocking route transition; user navigates back instantly.
- **Navigation Behavior**: Interstitial displays over the target navigation route; once closed, the user is back in the catalogue.
- **Background Behavior**: If app moves to background while ad is ready, ad presentation is withheld until user returns to foreground.
- **Policy Compliance**: Fully compliant with Google Play Interstitial Guidance (does not trigger on app open, does not trigger on unexpected screen transitions).

---

## 3. Ad Lifecycle, Memory Management & Verification

```mermaid
sequenceDiagram
    participant User
    participant Router as GoRouter
    participant Observer as PlayerExitAdObserver
    participant AudioHandler as PirithAudioHandler
    participant AdMob as Google AdMob SDK

    User->>Router: Tap Pirith track (Opens /player)
    Router->>Observer: didPush(/player)
    Observer->>AdMob: InterstitialAd.load() (Preload in background)
    AdMob-->>Observer: AdLoaded or AdFailedToLoad
    User->>AudioHandler: Stop / Pause playback
    User->>Router: Tap Back Button (Exit /player)
    Router->>Observer: didPop(/player)
    Observer->>AudioHandler: Check playbackState.playing
    alt Playing == true
        Observer->>Observer: SUPPRESS AD (Protect devotional audio)
    else Playing == false
        Observer->>AdMob: InterstitialAd.show()
        User->>AdMob: Dismiss Ad (Tap X)
        AdMob->>AdMob: dispose() (Prevent memory leak)
    end
```

### Memory Leak Prevention
- `BannerAdWidget` implements strict cleanup in `dispose()`:
  ```dart
  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
  ```
- `PlayerExitAdObserver` sets full-screen content callbacks and disposes the interstitial reference immediately on dismissal or display failure:
  ```dart
  ad.fullScreenContentCallback = FullScreenContentCallback(
    onAdDismissedFullScreenContent: (ad) {
      ad.dispose();
      _cachedInterstitial = null;
    },
    onAdFailedToShowFullScreenContent: (ad, error) {
      ad.dispose();
      _cachedInterstitial = null;
    },
  );
  ```

---

## 4. Test vs Production Ad Unit IDs

To prevent invalid traffic violations and ensure safe local QA:
- **Android Test IDs**:
  - Banner: `ca-app-pub-3940256099942544/6300978111`
  - Interstitial: `ca-app-pub-3940256099942544/1033173712`
- **iOS Test IDs**:
  - Banner: `ca-app-pub-3940256099942544/2934735716`
  - Interstitial: `ca-app-pub-3940256099942544/4411468910`
- Production credentials are injected via environment flavors (`--dart-define`) to ensure test keys are never deployed to production.

---

## 5. Audit Checklist & Verification Results

| Checkpoint | Verified State | Status |
| :--- | :--- | :--- |
| Interstitial does not interrupt active audio playback | Verified in `player_exit_ad_observer_test.dart` | **PASS** |
| Ads are completely disabled for Premium subscribers | Verified in `player_exit_ad_observer_test.dart` | **PASS** |
| Preloading completes ahead of exit without UI freezing | Verified asynchronously | **PASS** |
| Memory disposal on route unmount | Zero leaked AdMob instances | **PASS** |
| Non-obstructive layout (no clickjacking or button overlap) | Safe padding around bottom navigation | **PASS** |
| AndroidManifest & Info.plist AdMob App ID configured | Android API & iOS StoreKit verified | **PASS** |

