import '../entities/history_entry.dart';

/// Recently-played abstraction — see docs/09_development_roadmap.md
/// (Phase 7). Same V1 scope note as FavoritesRepository: local-only for
/// now, Firestore sync for signed-in users is a deliberate fast-follow.
abstract interface class HistoryRepository {
  /// Most-recently-played first.
  Stream<List<HistoryEntry>> get historyStream;

  List<HistoryEntry> get currentHistory;

  /// Records [pirithId] as just played, moving it to the front if it was
  /// already in the history, and caps the list length.
  Future<void> recordPlayed(String pirithId);
}
