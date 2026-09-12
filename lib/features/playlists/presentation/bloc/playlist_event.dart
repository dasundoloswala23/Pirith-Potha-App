part of 'playlist_bloc.dart';

sealed class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

class PlaylistCreated extends PlaylistEvent {
  const PlaylistCreated({
    required this.name,
    this.description = '',
    this.initialPirithId,
  });

  final String name;
  final String description;

  /// Set when the playlist is created from the add-to-playlist sheet, so
  /// "new playlist" and "add this Pirith to it" stay a single gesture — and
  /// a single event, since only the repository knows the generated id.
  final String? initialPirithId;

  @override
  List<Object?> get props => [name, description, initialPirithId];
}

class PlaylistRenamed extends PlaylistEvent {
  const PlaylistRenamed({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [id, name, description];
}

class PlaylistDeleted extends PlaylistEvent {
  const PlaylistDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class PlaylistItemAdded extends PlaylistEvent {
  const PlaylistItemAdded({required this.playlistId, required this.pirithId});

  final String playlistId;
  final String pirithId;

  @override
  List<Object?> get props => [playlistId, pirithId];
}

class PlaylistItemRemoved extends PlaylistEvent {
  const PlaylistItemRemoved({required this.playlistId, required this.pirithId});

  final String playlistId;
  final String pirithId;

  @override
  List<Object?> get props => [playlistId, pirithId];
}

class PlaylistItemsReordered extends PlaylistEvent {
  const PlaylistItemsReordered({
    required this.playlistId,
    required this.oldIndex,
    required this.newIndex,
  });

  final String playlistId;

  /// From `ReorderableListView.onReorderItem`: [newIndex] is the item's
  /// final position, already adjusted by the framework.
  final int oldIndex;
  final int newIndex;

  @override
  List<Object?> get props => [playlistId, oldIndex, newIndex];
}

class _PlaylistsChanged extends PlaylistEvent {
  const _PlaylistsChanged(this.playlists);

  final List<Playlist> playlists;

  @override
  List<Object?> get props => [playlists];
}
