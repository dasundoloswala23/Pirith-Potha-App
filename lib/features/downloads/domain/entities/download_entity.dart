import 'package:equatable/equatable.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

/// Local download record for one Pirith — see docs/05_offline_download.md.
class DownloadEntity extends Equatable {
  const DownloadEntity({
    required this.pirithId,
    required this.status,
    this.progress = 0,
    this.localAudioPath,
  });

  final String pirithId;
  final DownloadStatus status;

  /// 0.0-1.0, only meaningful while [status] is [DownloadStatus.downloading].
  final double progress;
  final String? localAudioPath;

  DownloadEntity copyWith({
    DownloadStatus? status,
    double? progress,
    String? localAudioPath,
  }) {
    return DownloadEntity(
      pirithId: pirithId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localAudioPath: localAudioPath ?? this.localAudioPath,
    );
  }

  @override
  List<Object?> get props => [pirithId, status, progress, localAudioPath];
}
