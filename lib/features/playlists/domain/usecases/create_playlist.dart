import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

class CreatePlaylist {
  const CreatePlaylist(this._repository);

  final PlaylistRepository _repository;

  Future<Playlist> call({required String name, String description = ''}) =>
      _repository.create(name: name, description: description);
}
