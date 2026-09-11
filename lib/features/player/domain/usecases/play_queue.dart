import '../../../pirith/domain/entities/pirith_entity.dart';
import '../entities/playback_mode.dart';
import '../repositories/audio_repository.dart';

class PlayQueue {
  const PlayQueue(this._repository);

  final AudioRepository _repository;

  Future<void> call(
    List<PirithEntity> items, {
    int startIndex = 0,
    PlaybackMode? mode,
  }) => _repository.playQueue(items, startIndex: startIndex, mode: mode);
}
