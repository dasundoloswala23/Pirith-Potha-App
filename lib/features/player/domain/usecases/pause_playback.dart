import '../repositories/audio_repository.dart';

class PausePlayback {
  const PausePlayback(this._repository);

  final AudioRepository _repository;

  Future<void> call() => _repository.pause();
}
