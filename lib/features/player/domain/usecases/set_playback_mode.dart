import '../entities/playback_mode.dart';
import '../repositories/audio_repository.dart';

class SetPlaybackMode {
  const SetPlaybackMode(this._repository);

  final AudioRepository _repository;

  Future<void> call(PlaybackMode mode) => _repository.setMode(mode);
}
