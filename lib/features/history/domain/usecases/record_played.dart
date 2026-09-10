import '../repositories/history_repository.dart';

class RecordPlayed {
  const RecordPlayed(this._repository);

  final HistoryRepository _repository;

  Future<void> call(String pirithId) => _repository.recordPlayed(pirithId);
}
