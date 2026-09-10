import '../repositories/audio_repository.dart';

class StopPlayback {
  const StopPlayback(this._repository);

  final AudioRepository _repository;

  Future<void> call() => _repository.stop();
}
