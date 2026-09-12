import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/error_reporter.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';

/// SharedPreferences-backed playlist store, following the same shape as
/// [FavoritesRepositoryImpl]: eager in-memory list, [initialize] at startup,
/// write-then-emit on every mutation.
///
/// Playlists are JSON-encoded rather than using the history repository's
/// `::`-delimited format, because names and descriptions are user-typed and
/// could contain the separator.
class PlaylistRepositoryImpl implements PlaylistRepository {
  PlaylistRepositoryImpl(this._prefs);

  static const _key = 'playlists_v1';

  final SharedPreferences _prefs;
  final _controller = StreamController<List<Playlist>>.broadcast();

  List<Playlist> _playlists = [];

  /// Last timestamp handed out by [_now].
  ///
  /// `DateTime.now()` is only millisecond-resolution on some platforms
  /// (Windows among them), so two playlists created in quick succession can
  /// report the *same* microsecond. That collided ids and made
  /// "newest-updated first" ambiguous. Issuing strictly increasing
  /// timestamps removes both problems at the source.
  DateTime? _lastIssued;

  DateTime _now() {
    final now = DateTime.now();
    final last = _lastIssued;
    final issued = last == null || now.isAfter(last)
        ? now
        : last.add(const Duration(microseconds: 1));
    _lastIssued = issued;
    return issued;
  }

  Future<void> initialize() async {
    final raw = _prefs.getStringList(_key) ?? [];
    _playlists = raw.map(_decode).whereType<Playlist>().toList();
    _sort();
  }

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
    final now = _now();
    final playlist = Playlist(
      // Unique because [_now] is strictly increasing — no `uuid`
      // dependency needed for a device-local id.
      id: 'pl_${now.microsecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      pirithIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    _playlists = [playlist, ..._playlists];
    await _persist();
    return playlist;
  }

  @override
  Future<void> rename(
    String id, {
    required String name,
    String? description,
  }) async {
    await _update(id, (playlist) {
      return playlist.copyWith(
        name: name.trim(),
        description: description?.trim(),
        updatedAt: _now(),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    _playlists = _playlists.where((playlist) => playlist.id != id).toList();
    await _persist();
  }

  @override
  Future<bool> addItem(String playlistId, String pirithId) async {
    final playlist = playlistById(playlistId);
    if (playlist == null || playlist.pirithIds.contains(pirithId)) return false;

    await _update(playlistId, (current) {
      return current.copyWith(
        pirithIds: [...current.pirithIds, pirithId],
        updatedAt: _now(),
      );
    });
    return true;
  }

  @override
  Future<void> removeItem(String playlistId, String pirithId) async {
    await _update(playlistId, (playlist) {
      return playlist.copyWith(
        pirithIds: playlist.pirithIds.where((id) => id != pirithId).toList(),
        updatedAt: _now(),
      );
    });
  }

  @override
  Future<void> reorder(String playlistId, int oldIndex, int newIndex) async {
    await _update(playlistId, (playlist) {
      final ids = [...playlist.pirithIds];
      if (oldIndex < 0 || oldIndex >= ids.length) return playlist;

      final target = newIndex.clamp(0, ids.length - 1);
      if (target == oldIndex) return playlist;

      ids.insert(target, ids.removeAt(oldIndex));
      return playlist.copyWith(pirithIds: ids, updatedAt: _now());
    });
  }

  Future<void> _update(String id, Playlist Function(Playlist) transform) async {
    var changed = false;
    _playlists = _playlists.map((playlist) {
      if (playlist.id != id) return playlist;
      changed = true;
      return transform(playlist);
    }).toList();
    if (!changed) return;
    await _persist();
  }

  Future<void> _persist() async {
    _sort();
    try {
      await _prefs.setStringList(
        _key,
        _playlists.map((playlist) => jsonEncode(playlist.toJson())).toList(),
      );
    } catch (error, stackTrace) {
      // The in-memory list is already updated, so the user's action isn't
      // lost for this session — only its persistence is, and there is
      // nothing they could do about it.
      reportNonFatal(error, stackTrace, reason: 'Failed to save playlists');
    }
    _controller.add(List.unmodifiable(_playlists));
  }

  void _sort() {
    _playlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Playlist? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return Playlist.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }
}
