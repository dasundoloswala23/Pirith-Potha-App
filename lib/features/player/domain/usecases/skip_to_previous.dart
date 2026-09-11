import '../repositories/audio_repository.dart';

class SkipToPrevious {
  const SkipToPrevious(this._repository);

  final AudioRepository _repository;

  Future<void> call() => _repository.skipToPrevious();
}
