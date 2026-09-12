import 'dart:async';

import 'package:pitithpotha/features/playlists/domain/entities/playlist.dart';
import 'package:pitithpotha/features/playlists/domain/repositories/playlist_repository.dart';

/// In-memory [PlaylistRepository] for BLoC/widget tests, so they don't need
/// SharedPreferences. Mirrors the real implementation's observable
/// behaviour: write-then-emit, newest-updated first, idempotent [addItem],
/// and [reorder] taking the item's final index.
class FakePlaylistRepository implements PlaylistRepository {
  final _controller = StreamController<List<Playlist>>.broadcast();

  List<Playlist> _playlists = [];
  int _nextId = 0;

  @override
  Stream<List<Playlist>> get playlistsStream => _controller.stream;

  @override
  List<Playlist> get currentPlaylists => List.unmodifiable(_playlists);

  @override
  Playlist? playlistById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  @override
  Future<Playlist> create({
    required String name,
    String description = '',
  }) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: 'pl_${_nextId++}',
      name: name.trim(),
      description: description.trim(),
      pirithIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    _playlists = [playlist, ..._playlists];
    _emit();
    return playlist;
  }

  @override
  Future<void> rename(
    String id, {
    required String name,
    String? description,
  }) async {
    _update(
      id,
      (playlist) =>
          playlist.copyWith(name: name.trim(), description: description?.trim()),
    );
  }

  @override
  Future<void> delete(String id) async {
    _playlists = _playlists.where((playlist) => playlist.id != id).toList();
    _emit();
  }

  @override
  Future<bool> addItem(String playlistId, String pirithId) async {
    final playlist = playlistById(playlistId);
    if (playlist == null || playlist.pirithIds.contains(pirithId)) return false;
    _update(
      playlistId,
      (current) =>
          current.copyWith(pirithIds: [...current.pirithIds, pirithId]),
    );
    return true;
  }

  @override
  Future<void> removeItem(String playlistId, String pirithId) async {
    _update(
      playlistId,
      (playlist) => playlist.copyWith(
        pirithIds: playlist.pirithIds.where((id) => id != pirithId).toList(),
      ),
    );
  }

  @override
  Future<void> reorder(String playlistId, int oldIndex, int newIndex) async {
    _update(playlistId, (playlist) {
      final ids = [...playlist.pirithIds];
      if (oldIndex < 0 || oldIndex >= ids.length) return playlist;
      final target = newIndex.clamp(0, ids.length - 1);
      if (target == oldIndex) return playlist;
      ids.insert(target, ids.removeAt(oldIndex));
      return playlist.copyWith(pirithIds: ids);
    });
  }

  void _update(String id, Playlist Function(Playlist) transform) {
    var changed = false;
    _playlists = _playlists.map((playlist) {
      if (playlist.id != id) return playlist;
      changed = true;
      return transform(playlist);
    }).toList();
    if (changed) _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_playlists));
}
