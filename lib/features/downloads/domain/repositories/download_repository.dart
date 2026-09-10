import '../../../pirith/domain/entities/pirith_entity.dart';
import '../entities/download_entity.dart';

/// Offline download abstraction — see docs/05_offline_download.md. The
/// data-layer implementation owns the Dio transfer, local file system, and
/// per-item metadata (this repository impl *is* the "DownloadManager" the
/// docs describe; there's only ever one implementation, so no extra
/// indirection layer on top of it).
abstract interface class DownloadRepository {
  /// Emits the full download map (`pirithId` -> [DownloadEntity]) whenever
  /// any download's status/progress changes.
  Stream<Map<String, DownloadEntity>> get downloadsStream;

  Map<String, DownloadEntity> get currentDownloads;

  /// Restores state from disk (previously-completed downloads survive app
  /// restarts). Call once during app startup before relying on
  /// [currentDownloads].
  Future<void> initialize();

  Future<void> download(PirithEntity item);
  Future<void> cancelDownload(String pirithId);
  Future<void> deleteDownload(String pirithId);

  /// Local audio file path for [pirithId] if it's downloaded and the file
  /// still exists on disk, otherwise null. Used by playback to prefer the
  /// local copy over streaming — see docs/04_audio_architecture.md.
  String? localAudioPathFor(String pirithId);
}
