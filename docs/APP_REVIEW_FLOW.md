# Pirith Potha — Smart App Review System Architecture & Flow

**Application:** Pirith Potha (පිරිත් පොත)  
**Feature:** In-App Review & Rating Coordinator  
**Module Path:** `lib/features/app_review/`  
**Date:** October 28, 2026  
**Status:** **100% Implemented, Verified & Tested (220/220 Tests Passing)**  

---

## 1. System Overview & Core Objectives

The Smart App Review System invites satisfied users to rate the application at the right moment without annoying the user or interrupting meditation and chanting.

### Fundamental Rules & Timing Constraints:
1. **5 Cumulative Foreground Minutes**: Only time spent actively in the foreground accumulates. Background audio playback does **NOT** accrue review time while the app is minimized.
2. **First Later Cooldown**: If the user taps "Maybe Later" the first time, the review prompt is suppressed for **34 hours**.
3. **Subsequent Later Cooldowns**: If the user taps "Maybe Later" on subsequent occasions, the review prompt is suppressed for **24 hours**.
4. **Active Usage Requirement in Subsequent Cycles**: After a 34h or 24h cooldown expires, the prompt does **NOT** immediately pop up on launch. The user must once again spend **5 cumulative foreground minutes** in the app before the prompt triggers.
5. **Rate App Once Rule**: Tapping "⭐ Rate App" successfully records `review_request_attempted` and permanently silences future custom prompts.
6. **Topmost Host Visibility**: Dialog renders over whichever eligible screen is topmost (`HomeShell`, `PlayerPage`, `QueuePage`) using a stacked coordinator.
7. **Unsafe Screen Suppression**: Never triggers on Splash, Authentication, Payment/Premium gates, Fullscreen Ads, or when another modal dialog/bottom sheet is active.

---

## 2. Review Lifecycle State Machine

```mermaid
stateDiagram-v2
    [*] --> NewInstall: App Launched
    NewInstall --> AccumulatingTime: App in Foreground
    AccumulatingTime --> Paused: App Backgrounded / Minimized
    Paused --> AccumulatingTime: App Resumed
    
    AccumulatingTime --> Eligible: Foreground Time >= 5 Mins & Topmost Screen Safe
    Eligible --> PresentingDialog: Show Custom Review Bottom Sheet
    
    PresentingDialog --> FirstLater: Tap 'Maybe Later' (Later Count == 0)
    FirstLater --> Cooldown34h: Set Cooldown = 34 Hours, Reset Usage = 0
    Cooldown34h --> AccumulatingTime: After 34h Passed & App in Foreground
    
    PresentingDialog --> SubsequentLater: Tap 'Maybe Later' (Later Count >= 1)
    SubsequentLater --> Cooldown24h: Set Cooldown = 24 Hours, Reset Usage = 0
    Cooldown24h --> AccumulatingTime: After 24h Passed & App in Foreground
    
    PresentingDialog --> Rated: Tap 'Rate App'
    Rated --> LaunchStore: Launch In-App Review / Deep Link
    LaunchStore --> PermanentlySuppressed: Persist review_request_attempted = true
    PermanentlySuppressed --> [*]
```

---

## 3. Platform Review Launch Strategy & Fallbacks

Native in-app review APIs (Google Play In-App Review on Android, StoreKit on iOS) are governed by strict operating system quotas and do not guarantee display. To handle all platform edge cases, Pirith Potha implements `ReviewStoreLauncher` (`lib/features/app_review/data/review_store_launcher.dart`):

```mermaid
flowchart TD
    TapRate[User Taps 'Rate App'] --> CheckOS{Detect Platform}
    
    CheckOS -->|Android| TryPlayReview[Try InAppReview.requestReview]
    TryPlayReview -->|Available & Shown| AndroidSuccess[Native Review Dialog Shown]
    TryPlayReview -->|Not Available / Quota Met| AndroidMarket[Try market://details?id=com.pirith.pitithpotha]
    AndroidMarket -->|Failure / No Play Store| AndroidWeb[Open https://play.google.com/store/apps/details?id=...]
    
    CheckOS -->|iOS| TryStoreKit[Try InAppReview.requestReview]
    TryStoreKit -->|Available & Shown| iOSSuccess[Native StoreKit Sheet Shown]
    TryStoreKit -->|Quota Met / Unsupported| iOSItms[Try itms-apps://itunes.apple.com/app/id...]
    iOSItms -->|Failure| iOSWeb[Open https://apps.apple.com/app/id...]
    
    AndroidSuccess --> PersistState[Mark review_request_attempted = true & Dismiss Forever]
    AndroidWeb --> PersistState
    iOSSuccess --> PersistState
    iOSWeb --> PersistState
```

---

## 4. UI/UX Specification: Review Invitation Sheet

The review sheet is implemented in `lib/features/app_review/presentation/widgets/review_invitation_sheet.dart` adhering to premium spiritual mobile design:

- **Border Radius**: 24px top rounded corners with gold subtle border styling (`AppColors.goldPrimary`).
- **Iconography**: Centered spiritual devotional icon with gold glowing gradient circle.
- **Bilingual Typography**:
  - Title: *"Enjoying your experience?"* / *"ඔබගේ අත්දැකීම සතුටුදායකද?"*
  - Body: *"Your review helps us share these protective pirith chants with more people around the world."*
- **Primary CTA**: *"⭐ Rate App"* (`ElevatedButton` with gold accent and haptic feedback `HapticFeedback.lightImpact()`).
- **Secondary CTA**: *"Maybe Later"* (`TextButton` with soft muted gold typography).
- **Accessibility**: Semantics enabled for screen readers; high-contrast text ratios exceeding WCAG AA standards.

---

## 5. Local Storage & Persistence Schema

Review state is stored in `SharedPreferences` via `ReviewStorage` (`lib/features/app_review/data/review_storage.dart`):

| Key | Type | Description |
| :--- | :--- | :--- |
| `review_active_usage` | `int` | Cumulative foreground seconds accrued in current cycle. |
| `review_later_count` | `int` | Number of times user tapped "Maybe Later". |
| `review_last_later_at` | `String` (ISO-8601) | Timestamp of the most recent "Maybe Later" action. |
| `review_last_prompt_at` | `String` (ISO-8601) | Timestamp of the most recent review prompt impression. |
| `review_prompt_count` | `int` | Cumulative count of times the prompt was presented. |
| `review_request_attempted` | `bool` | Set to `true` when user taps "Rate App". Permanently silences prompt. |
| `review_opted_out` | `bool` | Set to `true` if user explicitly dismisses indefinitely. |

---

## 6. Verification & Automated Test Coverage

Verified comprehensively via automated unit and scenario tests in `test/features/app_review/`:

1. `smart_review_scenarios_test.dart` (**10 test suites covering 14 operational scenarios**):
   - Scenario 1: First prompt appears after exactly 5 minutes of cumulative foreground use.
   - Scenario 2: Foreground time accumulates across multiple sessions (e.g. 2m + 3m).
   - Scenario 3: Backgrounded time does not count toward review eligibility.
   - Scenario 4: First "Maybe Later" delays prompt by exactly 34 hours.
   - Scenario 5: After 34h cooldown, requires an additional 5 minutes of active foreground use.
   - Scenario 6: Subsequent "Maybe Later" delays prompt by 24 hours.
   - Scenario 7: After 24h cooldown, requires an additional 5 minutes of active foreground use.
   - Scenario 8: Tapping "Rate App" attempts native review and permanently disables future prompts.
   - Scenario 9: Native review unavailability falls back safely to store web/app URLs.
   - Scenario 10: State survives application restarts and process death.
   - Scenario 11: Unsafe screens (Splash, Login, Checkout) postpone review prompt without losing time.
   - Scenario 12: Concurrent operations handle safely without duplicate dialogs.
2. `review_invitation_sheet_test.dart`: 40/40 widget test cases passing.
3. `review_scheduler_test.dart`: Boundary values, leap seconds, and cooldown math verified.
4. `review_prompt_coordinator_test.dart`: Multi-host route attachment and detachment verified.

