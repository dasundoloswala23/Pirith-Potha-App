# 06 — Authentication

## Principle

Listening to free Pirith must never require an account. Authentication is
only needed for features that sync across devices (favorites/history sync,
future premium entitlement).

## Supported methods

- Guest / anonymous (Firebase Anonymous Auth) — default on first launch
- Google Sign-In
- Apple Sign-In (required for iOS App Store if any other third-party login
  is offered)

## Flow

```
Guest (anonymous uid)
  ↓ user opts to sign in
Google / Apple login
  ↓
Link anonymous account to the chosen provider (Firebase account linking)
  ↓
Local guest data (favorites/history stored locally) merges into
users/{uid}/favorites, users/{uid}/history without duplicating records
```

Account linking (rather than creating a brand-new uid on sign-in) preserves
whatever the guest already favorited/downloaded/played, which is the reason
linking is required instead of a plain sign-in call.

## Architecture

```
AuthBloc
   ↓
Auth use cases (SignInAnonymously, SignInWithGoogle, SignInWithApple, SignOut, LinkAccount)
   ↓
AuthRepository (interface, domain layer)
   ↓
Firebase Auth data source (data layer)
```

`AuthBloc` states: `AuthInitial`, `AuthLoading`, `Authenticated` (carries
user + whether it's a guest/anonymous session), `Unauthenticated`,
`AuthError`.

## Session persistence

Firebase Auth's own persistence handles session survival across app
restarts; `AuthBloc` listens to `authStateChanges()`/`idTokenChanges()` on
startup to determine initial state rather than re-deriving it manually.

## Sign-out behavior

Signing out of a linked account does not delete local downloads (downloads
are device-local and independent of auth state). Favorites/history that were
only synced to the cloud become inaccessible until the user signs back in;
this is acceptable and doesn't need special-casing beyond returning to guest
mode.

## Security notes

- Never trust client-provided `isPremium`/role claims for anything
  security-sensitive; see [`07_monetization.md`](07_monetization.md) for the
  premium entitlement model.
- Firestore rules must restrict `users/{uid}` reads/writes to the matching
  authenticated (including anonymous) uid — see
  [`03_database_schema.md`](03_database_schema.md).
