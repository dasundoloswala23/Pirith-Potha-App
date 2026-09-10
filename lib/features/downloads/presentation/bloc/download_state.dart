part of 'download_bloc.dart';

sealed class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

/// Before [DownloadRepository.initialize] has resolved once.
class DownloadsLoading extends DownloadState {
  const DownloadsLoading();
}

class DownloadsLoaded extends DownloadState {
  const DownloadsLoaded(this.downloads);

  final Map<String, DownloadEntity> downloads;

  DownloadEntity? statusFor(String pirithId) => downloads[pirithId];

  List<DownloadEntity> get completed =>
      downloads.values.where((d) => d.status == DownloadStatus.downloaded).toList();

  @override
  List<Object?> get props => [downloads];
}
