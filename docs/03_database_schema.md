# 03 — Database Schema

## Principle

Firestore stores **metadata only**. Firebase Storage stores **files** (audio,
covers). Local device storage stores downloaded files + cached metadata for
offline use. Never store large binaries in Firestore or in the local
key-value DB.

## Firestore collections

```
pirith/{pirithId}
categories/{categoryId}
users/{uid}
  users/{uid}/favorites/{pirithId}
  users/{uid}/history/{pirithId}
playlists/{playlistId}
app_config/config
premium/plans
```

### `pirith/{pirithId}`

```json
{
  "title": "Rathana Sutta",
  "titleSinhala": "රතන සූත්‍රය",
  "description": "...",
  "descriptionSinhala": "...",
  "coverUrl": "...",
  "audioUrl": "...",
  "duration": 1240,
  "categoryId": "sutta",
  "isPremium": false,
  "isFeatured": false,
  "isActive": true,
  "sortOrder": 1,
  "playCount": 0,
  "downloadCount": 0,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

`playCount`/`downloadCount` are aggregate counters (written server-side, e.g.
by a Cloud Function reacting to play/download analytics events — never
incremented directly by the client) used to sort "Popular" sections; they
default to `0` and are read-only from the mobile app. Kept in sync with the
admin app's schema doc, which introduced them first.

### `categories/{categoryId}`

```json
{
  "name": "Sutta",
  "nameSinhala": "සූත්‍ර",
  "icon": "...",
  "sortOrder": 1
}
```

### `users/{uid}`

```json
{
  "displayName": "...",
  "email": "...",
  "photoUrl": "...",
  "provider": "google | apple | anonymous",
  "isPremium": false,
  "languagePreference": "si | en",
  "createdAt": "timestamp"
}
```

`favorites` and `history` are subcollections keyed by `pirithId`, storing at
minimum `{ addedAt / playedAt: timestamp }` — the Pirith document itself is
looked up by id, not duplicated.

## Firebase Storage layout

```
/covers/{pirithId}.webp
/audio/free/{pirithId}.mp3
/audio/premium/{pirithId}.mp3
/app/banners/...
```

Covers use WebP. Audio starts as MP3 for simplicity.

## Local storage (device)

Two distinct stores — do not conflate them:

1. **Metadata/cache DB** (Hive or Isar) — downloaded-Pirith records, favorites
   (guest mode), recently played, playback position, settings, cached
   Pirith/category metadata for offline browsing.
2. **File system** (`path_provider`) — actual downloaded audio + cover files:

```
ApplicationDocuments/
  pirith/
    {pirithId}/
      audio.mp3
      cover.webp
      metadata.json
```

A downloaded Pirith must be fully playable with zero Firebase calls: the
local DB record plus the local file are sufficient.

## Security model (summary — see `06_authentication.md` for auth-specific rules)

- `pirith`, `categories`, `app_config`: public read, admin-only write.
- `users/{uid}` and its subcollections: readable/writable only by the owning
  authenticated user (including anonymous/guest uids).
- No collection should ever use `allow read, write: if true;` in production
  rules.
