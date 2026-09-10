import 'package:audio_service/audio_service.dart';

import '../../../../core/audio/pirith_audio_handler.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../downloads/domain/repositories/download_repository.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/playback_status.dart';
import '../../domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl(this._handler, this._downloadRepository);

  final PirithAudioHandler _handler;
  final DownloadRepository _downloadRepository;

  PirithEntity? _currentItem;

  @override
  PirithEntity? get currentItem => _currentItem;

  @override
  Stream<PlaybackStatus> get statusStream => _handler.playbackState.map(_toStatus);

  @override
  Stream<Duration> get positionStream => _handler.positionStream;

  @override
  Stream<Duration?> get durationStream => _handler.mediaItem.map((item) => item?.duration);

  @override
  Future<void> play(PirithEntity item) async {
    _currentItem = item;
    // Prefer the local file when this Pirith is downloaded, so playback
    // needs zero network calls — see docs/05_offline_download.md.
    final localPath = _downloadRepository.localAudioPathFor(item.id);
    final source = localPath != null ? Uri.file(localPath).toString() : item.audioUrl;

    final mediaItem = MediaItem(
      id: item.id,
      title: item.titleSinhala,
      artist: item.title,
      duration: Duration(seconds: item.duration),
      artUri: item.coverUrl.isNotEmpty ? Uri.tryParse(item.coverUrl) : null,
      extras: {'audioUrl': source},
    );
    try {
      await _handler.playMediaItem(mediaItem);
    } catch (_) {
      throw AppException(
        localPath != null
            ? const UnknownFailure('Could not play this Pirith')
            : const NetworkFailure('Could not play this Pirith'),
      );
    }
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> seekTo(Duration position) => _handler.seek(position);

  @override
  Future<void> stop() => _handler.stop();

  PlaybackStatus _toStatus(PlaybackState state) {
    if (state.processingState == AudioProcessingState.error) return PlaybackStatus.error;
    if (state.processingState == AudioProcessingState.loading) return PlaybackStatus.loading;
    if (state.processingState == AudioProcessingState.buffering) {
      return PlaybackStatus.buffering;
    }
    if (state.processingState == AudioProcessingState.completed) {
      return PlaybackStatus.completed;
    }
    return state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
  }
}
