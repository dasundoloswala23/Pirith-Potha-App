import '../repositories/playlist_repository.dart';

class RemovePirithFromPlaylist {
  const RemovePirithFromPlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call(String playlistId, String pirithId) =>
      _repository.removeItem(playlistId, pirithId);
}
