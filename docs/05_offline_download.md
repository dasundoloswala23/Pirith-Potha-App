# 05 — Offline Download

## Goal

Users can download a Pirith and play it later with no internet connection at
all — no Firebase calls required for an already-downloaded item.

## Layering

```
UI (download button, progress indicator, Downloads screen)
      ↓
DownloadBloc
      ↓
Download use cases (Download, Cancel, Retry, Delete)
      ↓
DownloadRepository (interface, domain layer)
      ↓
DownloadManager (data layer — owns Dio transfer + local file system + local DB record)
```

## Flow

```
Firestore (pirith doc: audioUrl, coverUrl)
      ↓
DownloadManager fetches file via Dio, reports progress
      ↓
Saved to ApplicationDocuments/pirith/{pirithId}/audio.mp3 (+ cover.webp)
      ↓
Local DB record written: { pirithId, status: downloaded, localAudioPath, localCoverPath, downloadedAt }
```

See [`03_database_schema.md`](03_database_schema.md) for the exact local file
layout and DB store separation (metadata DB vs. file system).

## States to support

- Not downloaded
- Downloading (with progress 0–100%)
- Downloaded
- Failed (with retry)
- Cancelled (mid-download)

## Required behaviors

- Detect an existing/in-progress download for the same Pirith (no duplicate
  downloads).
- Cancel an in-progress download and clean up any partial file.
- Delete a completed download (remove file + local DB record).
- Retry a failed download.
- Downloads screen lists all downloaded items, works fully offline.
- Handle: insufficient device storage, corrupted/partial files, interrupted
  downloads (app killed mid-transfer), network loss mid-download, a file
  that's referenced in the local DB but missing on disk (self-heal by
  marking it "not downloaded" rather than crashing).

## Offline-first repository pattern

Every repository that serves catalogue/audio data (not just downloads)
should prefer local data when available and fall back to remote:

```
                 ┌── Firestore (remote data source)
App → Repository ┤
                 └── Local DB / files (local data source)
```

When online: remote → repository → local cache write-through → UI.
When offline: local DB/files → repository → UI, no error shown for absence
of network as long as local data satisfies the request.

## Out of scope for the initial downloads phase

- Premium-gated download limits (deferred to the Premium phase — the
  `DownloadManager` should be written so a quota/permission check can be
  inserted later without restructuring it)
- Pause/resume of a download (nice-to-have; cancel + restart is acceptable
  for MVP if pause/resume proves complex with the chosen HTTP client)
