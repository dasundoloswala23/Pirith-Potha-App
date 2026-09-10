import '../repositories/download_repository.dart';

class DeleteDownload {
  const DeleteDownload(this._repository);

  final DownloadRepository _repository;

  Future<void> call(String pirithId) => _repository.deleteDownload(pirithId);
}
