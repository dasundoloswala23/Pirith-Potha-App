/// Favorites abstraction — see docs/09_development_roadmap.md (Phase 7).
///
/// V1 scope: local-only, device-persisted (works fully offline for guest
/// and signed-in users alike). Cross-device Firestore sync for signed-in
/// (non-anonymous) users is a deliberate fast-follow, not built yet — the
/// interface below doesn't leak local-vs-remote storage details to callers,
/// so adding sync later won't require changing anything above this layer.
abstract interface class FavoritesRepository {
  /// Favorited Pirith ids, most-recently-favorited first.
  Stream<List<String>> get favoriteIdsStream;

  List<String> get currentFavoriteIds;

  bool isFavorite(String pirithId);

  Future<void> toggleFavorite(String pirithId);
}
