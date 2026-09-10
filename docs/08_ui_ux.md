# 08 — UI/UX

## Visual reference

The approved visual design is a Figma Make prototype at
`C:\Users\thari\Downloads\Buddhist Audio App UI Design` (React/Tailwind
source in `src/App.tsx` / `src/index.css`). It is the canonical source for
exact colors, fonts, spacing, corner radii, and per-screen layout —
`lib/app/theme/app_colors.dart`, `app_theme.dart`, and `app_typography.dart`
already port its color tokens and font choices (Noto Serif Sinhala titles,
Noto Sans Sinhala body, Lora for English serif accents, Inter for UI text)
and the `PirithMark` widget reproduces its "dhamma wheel" logo exactly.
When Phases 4–7 build the real Home, Search, Categories, Player, Downloads,
Favorites, and Settings screens, match this prototype's layout and
animation feel (ripple/scale press states, slide-up transitions, the
gold-accent progress ring on the download button, the mini-player docked
above the bottom nav) rather than redesigning from scratch.

## Localization — V1 mobile UI is Sinhala-first

**Revised policy (supersedes the original "full bilingual UI" requirement
below the original docs implied):** the V1 mobile app's visible UI is
**Sinhala only** — natural, grammatically correct Sinhala, not literal
machine-translation. English stays only for official brand/platform names
(e.g. "Google", "YouTube", "Facebook"), genuinely untranslatable technical
terms, and content where an English title is intentionally shown alongside
the Sinhala one (e.g. a Pirith's English name shown smaller under its
Sinhala title). There is **no in-app language switcher** in V1 — don't build
one unless explicitly requested again.

- Use Flutter's standard localization stack: `flutter_localizations` + `intl`,
  with ARB files under `lib/core/l10n/arb/app_en.arb` and `app_si.arb`,
  code-generated via `flutter gen-l10n` (configured in `l10n.yaml`).
- Every user-facing string in every screen, dialog, snackbar, error message,
  and Android notification channel name goes through the generated
  `AppLocalizations` — no hardcoded literal strings in widgets, in either
  language.
- The app's `MaterialApp` pins `locale: const Locale('si')` directly rather
  than resolving from the device locale or a mutable controller.
- The `app_en.arb` file is **kept in sync** as the data/reference locale —
  not shown in the V1 UI, but present so a future language switch is an
  `AppLocalizations`/`locale` change, not a UI rewrite. Don't delete it or
  let it drift out of sync with the Sinhala strings.
- Sinhala text requires a font with full Sinhala glyph coverage; the app
  loads Noto Serif Sinhala (titles) and Noto Sans Sinhala (body/UI) via
  `google_fonts` — see `lib/app/theme/app_typography.dart`.
- Content fields that are inherently bilingual (Pirith title/description) are
  modeled as separate fields (`title` + `titleSinhala`, etc. — see
  [`03_database_schema.md`](03_database_schema.md)); the UI displays the
  Sinhala field, falling back to the English one if a Sinhala translation is
  missing rather than showing blank text. Do not remove the English fields
  from the data model — they're the future-bilingual-support path.

## Screens

### Home

Sections: search bar, featured Pirith, popular Pirith, categories, recently
played, downloaded. Each Pirith card shows: cover image, title (active
language), duration, play button, download status indicator, favorite
indicator, premium badge if applicable.

### Pirith details

Cover, Sinhala + English title, duration, description, Play, Download,
Favorite, related Pirith list.

### Full player + mini-player

Mini-player is persistent across the app while something is playing (or
paused), tap opens the full-screen player: cover, title, position/duration,
seek bar, play/pause/skip, download, favorite. Sleep timer control added in
V1.1 (see [`04_audio_architecture.md`](04_audio_architecture.md)).

### Downloads

List of downloaded items with offline indicator; works with no network.

### Favorites

Simple list, same card style as Home.

### Profile / Settings

Auth state (guest vs. signed in), a read-only language row (shows "සිංහල",
not a switch — see the localization policy above), favorites/downloads/
history shortcuts, Premium entry point (placeholder until V2), settings,
about, privacy policy.

### Social / community section

A warm, Sinhala-first community section (Home screen) inviting users to
follow the official YouTube and Facebook presence — not a literal "Follow us
on Facebook and YouTube" translation. Tapping a card opens the native app if
installed, otherwise the official URL in the external browser
(`url_launcher` with `LaunchMode.externalApplication`) — never an in-app
WebView. URLs live in one centralized constants file, never hardcoded in a
widget.

## Product framing

Organize content around usage moments rather than a flat alphabetical list —
e.g. "Daily Pirith", "Morning", "Before Sleep", "Metta", "Sutta" categories —
to reinforce that this is a digital chant book, not a generic audio player.
This maps directly onto the `categories` collection
([`03_database_schema.md`](03_database_schema.md)).

## Ads placement

See [`07_monetization.md`](07_monetization.md) — banners only, never over or
beside the player.
