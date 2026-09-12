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
  "titleEnglish": "Rathana Sutta",
  "titleSinhala": "රතන සූත්‍රය",
  "descriptionEnglish": "...",
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
  "nameEnglish": "Sutta",
  "nameSinhala": "සූත්‍ර",
  "imageUrl": "...",
  "sortOrder": 1,
  "isActive": true
}
```

The `*English`/`*Sinhala` field pairs are written by the admin web app and
must stay symmetric — the Dart models map them onto shorter property names
(`title`, `description`, `name`), so the property name and the Firestore key
deliberately differ. `imageUrl` and the category `isActive` flag are written
by the admin but not yet consumed by the mobile app.

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

1. **Key-value store** (`shared_preferences`) — downloaded-Pirith records,
   favorites (guest mode), recently played, playlists, settings, cached
   Pirith/category metadata for offline browsing.

   Earlier drafts of this document named Hive or Isar here. Neither was ever
   adopted: every local store in the app is SharedPreferences, JSON-encoded
   where the value isn't a plain string list (`playlists_v1`, the download
   records). The `sqflite` entry in `pubspec.lock` is a transitive
   dependency, not something the app uses. A real embedded database is only
   worth adding if a store outgrows whole-collection reads and writes —
   nothing does today.
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

The actual `firestore.rules`, `storage.rules`, and `firestore.indexes.json`
are **not** kept in this repo — they live in, and are deployed from, the
admin web app repo (`Pirith Potha Admin React`), which owns the shared
Firebase backend config for the `pithi-potha` project. This repo's
`firebase.json` is FlutterFire-generated and gets rewritten by
`flutterfire configure`, so it is not a safe place for them. Duplicating
them here previously left a stale copy that denied all admin writes.

Note the composite index that the catalogue query
(`where isActive == true` + `orderBy sortOrder`) depends on is declared
there — without it that query fails with `failed-precondition` and the app
falls back to an empty catalogue.
