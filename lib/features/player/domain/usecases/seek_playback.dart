import '../repositories/audio_repository.dart';

class SeekPlayback {
  const SeekPlayback(this._repository);

  final AudioRepository _repository;

  Future<void> call(Duration position) => _repository.seekTo(position);
}
