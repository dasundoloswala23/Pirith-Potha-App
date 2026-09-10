import '../../../pirith/domain/entities/pirith_entity.dart';
import '../repositories/audio_repository.dart';

class PlayPirith {
  const PlayPirith(this._repository);

  final AudioRepository _repository;

  Future<void> call(PirithEntity item) => _repository.play(item);
}
