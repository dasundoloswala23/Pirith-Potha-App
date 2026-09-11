import 'package:audio_service/audio_service.dart';

import '../../../../core/audio/pirith_audio_handler.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../downloads/domain/repositories/download_repository.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/playback_mode.dart';
import '../../domain/entities/playback_status.dart';
import '../../domain/repositories/audio_repository.dart';

class AudioRepositoryImpl implements AudioRepository {
  AudioRepositoryImpl(this._handler, this._downloadRepository);

  final PirithAudioHandler _handler;
  final DownloadRepository _downloadRepository;

  List<PirithEntity> _queue = const [];
  int _index = 0;
  PlaybackMode _mode = PlaybackMode.normal;

  @override
  PirithEntity? get currentItem =>
      _index >= 0 && _index < _queue.length ? _queue[_index] : null;

  @override
  List<PirithEntity> get queue => List.unmodifiable(_queue);

  @override
  PlaybackMode get mode => _mode;

  @override
  Stream<PlaybackStatus> get statusStream =>
      _handler.playbackState.map(_toStatus);

  @override
  Stream<Duration> get positionStream => _handler.positionStream;

  @override
  Stream<Duration?> get durationStream =>
      _handler.mediaItem.map((item) => item?.duration);

  @override
  Stream<int> get currentIndexStream => _handler.currentIndexStream
      .where((index) => index != null)
      .map((index) => _index = index!);

  @override
  Future<void> play(PirithEntity item) => playQueue([item]);

  @override
  Future<void> playQueue(
    List<PirithEntity> items, {
    int startIndex = 0,
    PlaybackMode? mode,
  }) async {
    if (items.isEmpty) return;
    _queue = List.unmodifiable(items);
    _index = startIndex.clamp(0, items.length - 1);
    if (mode != null) _mode = mode;

    final mediaItems = items.map(_toMediaItem).toList();
    try {
      // Mode is applied before loading so shuffle order is established for
      // the sequence we're about to play, not the previous one.
      await _handler.setPlaybackMode(_mode);
      await _handler.setQueue(mediaItems, initialIndex: _index);
    } catch (_) {
      throw AppException(
        _downloadRepository.localAudioPathFor(items[_index].id) != null
            ? const UnknownFailure('Could not play this Pirith')
            : const NetworkFailure('Could not play this Pirith'),
      );
    }
  }

  /// Resolution of local-vs-remote happens per item, at the moment the
  /// queue is built — see docs/05_offline_download.md. A download that
  /// finishes mid-queue therefore only takes effect next time the queue is
  /// built, which is the tradeoff for letting just_audio own the sequence.
  MediaItem _toMediaItem(PirithEntity item) {
    final localPath = _downloadRepository.localAudioPathFor(item.id);
    final source = localPath != null
        ? Uri.file(localPath).toString()
        : item.audioUrl;

    return MediaItem(
      id: item.id,
      title: item.titleSinhala,
      artist: item.title,
      duration: Duration(seconds: item.duration),
      artUri: item.coverUrl.isNotEmpty ? Uri.tryParse(item.coverUrl) : null,
      extras: {'audioUrl': source},
    );
  }

  @override
  Future<void> skipToNext() => _handler.skipToNext();

  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  @override
  Future<void> skipToIndex(int index) => _handler.skipToQueueItem(index);

  @override
  Future<void> setMode(PlaybackMode mode) async {
    _mode = mode;
    await _handler.setPlaybackMode(mode);
  }

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> resume() => _handler.play();

  @override
  Future<void> seekTo(Duration position) => _handler.seek(position);

  @override
  Future<void> stop() async {
    _queue = const [];
    _index = 0;
    await _handler.stop();
  }

  PlaybackStatus _toStatus(PlaybackState state) {
    if (state.processingState == AudioProcessingState.error) {
      return PlaybackStatus.error;
    }
    if (state.processingState == AudioProcessingState.loading) {
      return PlaybackStatus.loading;
    }
    if (state.processingState == AudioProcessingState.buffering) {
      return PlaybackStatus.buffering;
    }
    if (state.processingState == AudioProcessingState.completed) {
      return PlaybackStatus.completed;
    }
    return state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
  }
}
