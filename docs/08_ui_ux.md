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

## Localization (Sinhala + English) — applies to the whole app

The entire app UI ships in **Sinhala and English**, not just chant content.
This is a hard requirement, not a stretch goal.

- Use Flutter's standard localization stack: `flutter_localizations` + `intl`,
  with ARB files under `l10n/app_en.arb` and `l10n/app_si.arb`, code-generated
  via `flutter gen-l10n` (configured in `l10n.yaml`).
- Every user-facing string in every screen, dialog, snackbar, and error
  message goes through the generated `AppLocalizations` — no hardcoded
  English (or Sinhala) strings in widgets.
- Language selection: default to the device locale if it's Sinhala or
  English, otherwise default to Sinhala (primary audience). Persist the
  user's explicit choice (`languagePreference`) in local settings, and mirror
  it to `users/{uid}.languagePreference` once authenticated, so it's
  consistent across devices.
- A visible language switch belongs in Settings/Profile.
- Sinhala text requires a font with full Sinhala glyph coverage (e.g. Noto
  Sans Sinhala) bundled as an app asset — do not rely on the OS providing one
  on all Android versions/devices.
- Content fields that are inherently bilingual (Pirith title/description) are
  modeled as separate fields (`title` + `titleSinhala`, etc. — see
  [`03_database_schema.md`](03_database_schema.md)) and the UI picks the
  right one based on active language, falling back to the other if a
  translation is missing rather than showing blank text.

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

### Profile

Auth state (guest vs. signed in), language switch, favorites/downloads/
history shortcuts, Premium entry point (placeholder until V2), settings,
about, privacy policy.

## Product framing

Organize content around usage moments rather than a flat alphabetical list —
e.g. "Daily Pirith", "Morning", "Before Sleep", "Metta", "Sutta" categories —
to reinforce that this is a digital chant book, not a generic audio player.
This maps directly onto the `categories` collection
([`03_database_schema.md`](03_database_schema.md)).

## Ads placement

See [`07_monetization.md`](07_monetization.md) — banners only, never over or
beside the player.
