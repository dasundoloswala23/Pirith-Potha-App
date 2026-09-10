import 'package:audio_service/audio_service.dart';

import '../../../../core/audio/pirith_audio_handler.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/playback_status.dart';
import '../../domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl(this._handler);

  final PirithAudioHandler _handler;

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
    final mediaItem = MediaItem(
      id: item.id,
      title: item.titleSinhala,
      artist: item.title,
      duration: Duration(seconds: item.duration),
      artUri: item.coverUrl.isNotEmpty ? Uri.tryParse(item.coverUrl) : null,
      extras: {'audioUrl': item.audioUrl},
    );
    try {
      await _handler.playMediaItem(mediaItem);
    } catch (_) {
      throw const AppException(NetworkFailure('Could not play this Pirith'));
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
