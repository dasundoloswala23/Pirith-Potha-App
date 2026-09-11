import '../repositories/audio_repository.dart';

class SkipToNext {
  const SkipToNext(this._repository);

  final AudioRepository _repository;

  Future<void> call() => _repository.skipToNext();
}
