part of 'playlist_bloc.dart';

sealed class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object?> get props => [];
}

class PlaylistsLoading extends PlaylistState {
  const PlaylistsLoading();
}

class PlaylistsLoaded extends PlaylistState {
  const PlaylistsLoaded(this.playlists);

  /// Most-recently-updated first.
  final List<Playlist> playlists;

  Playlist? byId(String id) {
    for (final playlist in playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  bool contains(String playlistId, String pirithId) =>
      byId(playlistId)?.pirithIds.contains(pirithId) ?? false;

  @override
  List<Object?> get props => [playlists];
}
