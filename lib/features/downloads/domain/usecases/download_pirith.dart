import '../../../pirith/domain/entities/pirith_entity.dart';
import '../repositories/download_repository.dart';

class DownloadPirith {
  const DownloadPirith(this._repository);

  final DownloadRepository _repository;

  Future<void> call(PirithEntity item) => _repository.download(item);
}
