import '../repositories/audio_repository.dart';

class ResumePlayback {
  const ResumePlayback(this._repository);

  final AudioRepository _repository;

  Future<void> call() => _repository.resume();
}
