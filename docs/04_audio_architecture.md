# 04 — Audio Architecture

## Goal

Audio must keep playing when the app is backgrounded and when the phone
screen is locked, with notification/lock-screen media controls, Bluetooth/
headset button support, and correct handling of audio interruptions (calls,
other apps). This is the single most technically sensitive part of the app —
get it right before investing heavily in UI polish elsewhere.

## Stack

`just_audio` (playback engine) + `audio_service` (background service,
notification/lock-screen integration, OS media session).

## Layering

```
UI (mini-player, full player)
      ↓
PlayerBloc
      ↓
Audio use cases (Play, Pause, Seek, SkipNext, SkipPrevious, ...)
      ↓
AudioRepository (interface, domain layer)
      ↓
AudioPlayerManager (data layer — the ONLY place that touches just_audio/audio_service)
      ↓
just_audio + audio_service → OS audio session
```

Widgets never import `just_audio` or `audio_service` directly. All player
state (playing/paused/buffering/position/duration/error/queue) flows through
`PlayerBloc`.

## Required capabilities

- Play / pause / seek / stop
- Current position + duration streams
- Buffering / loading state
- Track completion handling
- Next / previous (queue-aware, for future playlists)
- Error handling (network failure mid-stream, corrupted file, etc.)
- Background playback (app in background)
- Lock-screen playback (screen locked)
- Android notification with play/pause/skip controls
- Lock-screen media controls (where platform supports it)
- Bluetooth / wired headset button + media key support
- Audio interruption handling (phone calls, other audio apps)

## Metadata

Use the Pirith's `title` / `titleSinhala` (per active language) and
`coverUrl` as the `MediaItem` displayed in the notification and lock screen.
Keep this consistent across: home card, details page, mini-player,
full-screen player, notification, and downloads list.

## Source resolution

`AudioPlayerManager` must accept either a remote Firebase Storage URL or a
local file path transparently — playback of a downloaded Pirith must not
depend on network access. The `AudioRepository` decides local-vs-remote
source resolution (checking the download store first) before handing a
source to the manager; `PlayerBloc` doesn't know the difference.

## Out of scope for the initial audio phase

- Playlists / queue reordering UI (build the queue-capable plumbing, but
  playlist management ships in V1.1)
- Sleep timer (V1.1 feature; can be layered on top of `PlayerBloc` later
  without changing `AudioPlayerManager`)
