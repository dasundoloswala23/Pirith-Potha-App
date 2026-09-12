import '../entities/playlist.dart';

/// Device-local playlist storage. Playlists are deliberately **not** synced
/// to Firestore: they need no account, and the app supports guest use — see
/// docs/03_database_schema.md.
abstract interface class PlaylistRepository {
  Stream<List<Playlist>> get playlistsStream;

  /// Newest-updated first, so a playlist just added to rises to the top.
  List<Playlist> get currentPlaylists;

  Playlist? playlistById(String id);

  Future<Playlist> create({required String name, String description = ''});

  Future<void> rename(String id, {required String name, String? description});

  Future<void> delete(String id);

  /// Adds [pirithId] to the end of the playlist. Returns `false` when the
  /// Pirith is already a member, which is what tells the UI to say
  /// "already in this playlist" rather than claiming a second add.
  Future<bool> addItem(String playlistId, String pirithId);

  Future<void> removeItem(String playlistId, String pirithId);

  /// Moves the item at [oldIndex] to [newIndex], where [newIndex] is its
  /// final position in the reordered list.
  ///
  /// This is exactly what `ReorderableListView.onReorderItem` reports — the
  /// framework already accounts for the dragged item being removed first,
  /// so nothing here (or in the caller) may adjust the index again. The
  /// older `onReorder` callback, which reports the raw drop slot, must not
  /// be wired to this.
  Future<void> reorder(String playlistId, int oldIndex, int newIndex);
}
