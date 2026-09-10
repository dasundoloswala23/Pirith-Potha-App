part of 'download_bloc.dart';

sealed class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class DownloadRequested extends DownloadEvent {
  const DownloadRequested(this.item);

  final PirithEntity item;

  @override
  List<Object?> get props => [item];
}

class DownloadCancelRequested extends DownloadEvent {
  const DownloadCancelRequested(this.pirithId);

  final String pirithId;

  @override
  List<Object?> get props => [pirithId];
}

class DownloadDeleteRequested extends DownloadEvent {
  const DownloadDeleteRequested(this.pirithId);

  final String pirithId;

  @override
  List<Object?> get props => [pirithId];
}

class _DownloadsChanged extends DownloadEvent {
  const _DownloadsChanged(this.downloads);

  final Map<String, DownloadEntity> downloads;

  @override
  List<Object?> get props => [downloads];
}
