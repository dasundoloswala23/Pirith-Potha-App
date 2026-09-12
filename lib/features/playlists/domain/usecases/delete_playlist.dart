import '../repositories/playlist_repository.dart';

class DeletePlaylist {
  const DeletePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
