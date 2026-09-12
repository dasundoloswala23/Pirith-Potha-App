import '../repositories/playlist_repository.dart';

class AddPirithToPlaylist {
  const AddPirithToPlaylist(this._repository);

  final PlaylistRepository _repository;

  /// `false` when the Pirith was already in the playlist.
  Future<bool> call(String playlistId, String pirithId) =>
      _repository.addItem(playlistId, pirithId);
}
