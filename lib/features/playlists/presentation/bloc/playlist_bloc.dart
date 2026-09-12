import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/firebase/analytics_service.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/usecases/add_pirith_to_playlist.dart';
import '../../domain/usecases/create_playlist.dart';
import '../../domain/usecases/delete_playlist.dart';
import '../../domain/usecases/remove_pirith_from_playlist.dart';
import '../../domain/usecases/rename_playlist.dart';
import '../../domain/usecases/reorder_playlist.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';

/// App-scoped BLoC (one instance for the whole app) so the playlists tab,
/// the detail screen and the add-to-playlist sheet all read the same list —
/// the same arrangement as [FavoritesBloc].
///
/// There are only two states. The store is fully in memory after
/// `initialize()`, so a mutation has no async gap for a separate "updating"
/// state to represent, and a transient "success" state would force a
/// redundant re-emit of the list; screens say what happened with a SnackBar
/// at the call site instead.
class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  PlaylistBloc({
    required PlaylistRepository playlistRepository,
    required CreatePlaylist createPlaylist,
    required RenamePlaylist renamePlaylist,
    required DeletePlaylist deletePlaylist,
    required AddPirithToPlaylist addPirithToPlaylist,
    required RemovePirithFromPlaylist removePirithFromPlaylist,
    required ReorderPlaylist reorderPlaylist,
    AnalyticsService? analytics,
  })  : _playlistRepository = playlistRepository,
        _createPlaylist = createPlaylist,
        _renamePlaylist = renamePlaylist,
        _deletePlaylist = deletePlaylist,
        _addPirithToPlaylist = addPirithToPlaylist,
        _removePirithFromPlaylist = removePirithFromPlaylist,
        _reorderPlaylist = reorderPlaylist,
        _analytics = analytics,
        super(const PlaylistsLoading()) {
    on<PlaylistCreated>(_onCreated);
    on<PlaylistRenamed>(_onRenamed);
    on<PlaylistDeleted>(_onDeleted);
    on<PlaylistItemAdded>(_onItemAdded);
    on<PlaylistItemRemoved>(_onItemRemoved);
    on<PlaylistItemsReordered>(_onItemsReordered);
    on<_PlaylistsChanged>((event, emit) => emit(PlaylistsLoaded(event.playlists)));

    add(_PlaylistsChanged(_playlistRepository.currentPlaylists));
    _subscription = _playlistRepository.playlistsStream.listen(
      (playlists) => add(_PlaylistsChanged(playlists)),
    );
  }

  final PlaylistRepository _playlistRepository;
  final CreatePlaylist _createPlaylist;
  final RenamePlaylist _renamePlaylist;
  final DeletePlaylist _deletePlaylist;
  final AddPirithToPlaylist _addPirithToPlaylist;
  final RemovePirithFromPlaylist _removePirithFromPlaylist;
  final ReorderPlaylist _reorderPlaylist;

  /// Optional so tests can construct the BLoC without a live Firebase
  /// Analytics instance; on device it is always injected.
  final AnalyticsService? _analytics;

  late final StreamSubscription<List<Playlist>> _subscription;

  Future<void> _onCreated(PlaylistCreated event, Emitter<PlaylistState> emit) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    final playlist = await _createPlaylist(
      name: name,
      description: event.description,
    );
    _analytics?.logPlaylistCreated(playlist.id);

    final pirithId = event.initialPirithId;
    if (pirithId != null) {
      await _addPirithToPlaylist(playlist.id, pirithId);
      _analytics?.logPirithAddedToPlaylist(playlist.id, pirithId);
    }
  }

  Future<void> _onRenamed(PlaylistRenamed event, Emitter<PlaylistState> emit) async {
    final name = event.name.trim();
    if (name.isEmpty) return;
    await _renamePlaylist(event.id, name: name, description: event.description);
  }

  Future<void> _onDeleted(PlaylistDeleted event, Emitter<PlaylistState> emit) async {
    await _deletePlaylist(event.id);
    _analytics?.logPlaylistDeleted(event.id);
  }

  Future<void> _onItemAdded(PlaylistItemAdded event, Emitter<PlaylistState> emit) async {
    final added = await _addPirithToPlaylist(event.playlistId, event.pirithId);
    if (added) {
      _analytics?.logPirithAddedToPlaylist(event.playlistId, event.pirithId);
    }
  }

  Future<void> _onItemRemoved(
    PlaylistItemRemoved event,
    Emitter<PlaylistState> emit,
  ) async {
    await _removePirithFromPlaylist(event.playlistId, event.pirithId);
    _analytics?.logPirithRemovedFromPlaylist(event.playlistId, event.pirithId);
  }

  Future<void> _onItemsReordered(
    PlaylistItemsReordered event,
    Emitter<PlaylistState> emit,
  ) async {
    await _reorderPlaylist(event.playlistId, event.oldIndex, event.newIndex);
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
