# 02 — Architecture

## Layering

Feature-first Clean Architecture:

```
lib/
  app/                 # app.dart, router.dart, theme/
  core/                # constants, errors, network, utils, services,
                        # audio/, storage/, l10n/
  features/
    auth/
    home/
    pirith/
    player/
    downloads/
    favorites/
    profile/
    premium/
      data/
      domain/
      presentation/
  main.dart
```

Each feature follows:

```
Presentation (screens, widgets, BLoC/Cubit)
      ↓
Domain (entities, use cases, repository interfaces)
      ↓
Data (repository implementations, remote + local data sources, models)
```

Dependency direction always points inward: presentation depends on domain,
data implements domain interfaces. Domain never imports Flutter/Firebase/audio
packages directly.

## State management

`flutter_bloc`. One BLoC/Cubit per feature-level concern (see each feature's
doc for its specific states/events). Widgets dispatch events/call cubit
methods and rebuild via `BlocBuilder`/`BlocListener`; they never call
repositories or platform SDKs directly.

## Dependency injection

`get_it`, registered in `core/di` (or `app/`), wired at `main.dart` startup:

```
main.dart → configureDependencies() → repositories → use cases → BLoCs → UI
```

Repositories and data sources are registered as lazy singletons; BLoCs as
factories (new instance per screen) unless a BLoC is intentionally app-scoped
(e.g. `AuthBloc`, `PlayerBloc`, `DownloadBloc` — these are long-lived/global).

## Routing

`go_router`, defined in `app/router.dart`. Route names centralized as
constants in `core/constants`. Deep-linking into a specific Pirith detail
page should be supported by the route structure from the start, even if not
wired to real deep links until later.

## Cross-cutting rules

- UI never directly touches Firebase, Firestore, Storage, or `just_audio`/
  `audio_service` — always through a repository/manager abstraction.
- Audio playback is centralized in a single `AudioPlayerManager` (see
  [`04_audio_architecture.md`](04_audio_architecture.md)).
- Downloads are centralized in a single `DownloadManager` (see
  [`05_offline_download.md`](05_offline_download.md)).
- Errors are mapped at the data layer into a small set of domain-level
  failure types (`core/errors`) — UI never handles raw `FirebaseException` /
  `DioException` etc.
- Offline-first: repositories query local cache/DB first where applicable and
  reconcile with remote when online, rather than assuming network access.

## Theming & localization

- `app/theme/` holds light/dark `ThemeData`.
- `core/l10n/` (or top-level `l10n/`) holds the Sinhala + English ARB files
  and generated localizations, per [`08_ui_ux.md`](08_ui_ux.md).
