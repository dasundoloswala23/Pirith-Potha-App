import '../repositories/playlist_repository.dart';

class RenamePlaylist {
  const RenamePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<void> call(String id, {required String name, String? description}) =>
      _repository.rename(id, name: name, description: description);
}
