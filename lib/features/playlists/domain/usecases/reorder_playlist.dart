import '../repositories/playlist_repository.dart';

class ReorderPlaylist {
  const ReorderPlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call(String playlistId, int oldIndex, int newIndex) =>
      _repository.reorder(playlistId, oldIndex, newIndex);
}
