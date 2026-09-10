import '../repositories/download_repository.dart';

class CancelDownload {
  const CancelDownload(this._repository);

  final DownloadRepository _repository;

  Future<void> call(String pirithId) => _repository.cancelDownload(pirithId);
}
