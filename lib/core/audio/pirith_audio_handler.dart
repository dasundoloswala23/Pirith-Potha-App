import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/player/domain/entities/playback_mode.dart';

/// The single place in the app that touches `just_audio`/`audio_service`
/// directly — see docs/04_audio_architecture.md. Wraps a `just_audio`
/// player and broadcasts its state through `audio_service` so the OS
/// notification, lock screen, and Bluetooth/headset controls all stay in
/// sync automatically. Everything above [AudioRepositoryImpl] talks to
/// this handler only through the `AudioHandler` API plus the extra streams
/// below.
///
/// Queue playback uses `just_audio`'s own sequence support rather than a
/// hand-rolled "load the next file when this one ends" loop: loop and
/// shuffle modes, gapless advance, and the lock-screen skip buttons all
/// come from the player itself, and there is only ever one player.
class PirithAudioHandler extends BaseAudioHandler with SeekHandler {
  PirithAudioHandler(this._player) {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
          ),
        );
      },
    );

    // Keep the notification/lock-screen metadata pointed at whatever the
    // player actually moved to, including auto-advance we didn't trigger.
    _player.currentIndexStream.listen((index) {
      final items = queue.value;
      if (index == null || index < 0 || index >= items.length) return;
      mediaItem.add(items[index]);
    });

    _player.processingStateStream.listen((state) {
      if (state != ProcessingState.completed) return;
      // With a loop mode set, or more items to come, just_audio advances on
      // its own — only the genuine end of playback needs handling, and it
      // rewinds rather than leaving the player parked at the end so the
      // play button works again.
      if (_player.loopMode != LoopMode.off) return;
      _player.pause();
      _player.seek(Duration.zero, index: 0);
    });
  }

  final AudioPlayer _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Index of the playing item within the queue passed to [setQueue].
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  /// Loads a queue and starts at [initialIndex].
  ///
  /// Each [MediaItem] carries its already-resolved source (local file or
  /// remote URL) in `extras['audioUrl']`; resolving that is the
  /// repository's job, since only it knows what has been downloaded.
  Future<void> setQueue(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) return;

    // Filter once, then publish *that* list. This used to skip empty-URL
    // items while building sources but still publish the unfiltered list to
    // `queue`/`mediaItem`, so the indices just_audio reported addressed a
    // shorter array than the one they were used to index — every track after
    // a skipped one showed the wrong title and artwork.
    final playable = items
        .where((item) => (item.extras?['audioUrl'] as String? ?? '').isNotEmpty)
        .toList();
    if (playable.isEmpty) {
      // Loud rather than silent: AudioRepositoryImpl.playQueue wraps this in
      // a try/catch and turns it into an AppException, where a bare `return`
      // left the UI on a spinner that never resolved. Callers filter first,
      // so reaching this is a bug.
      throw StateError('setQueue called with no playable items');
    }

    final index = initialIndex.clamp(0, playable.length - 1);
    queue.add(playable);
    mediaItem.add(playable[index]);

    final sources = [
      for (final item in playable)
        AudioSource.uri(
          Uri.parse(item.extras!['audioUrl'] as String),
          tag: item,
        ),
    ];

    await _player.setAudioSources(sources, initialIndex: index);
    await play();
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) =>
      setQueue([mediaItem]);

  Future<void> setPlaybackMode(PlaybackMode mode) async {
    await _player.setLoopMode(switch (mode) {
      PlaybackMode.repeatOne => LoopMode.one,
      PlaybackMode.repeatAll => LoopMode.all,
      PlaybackMode.normal || PlaybackMode.shuffle => LoopMode.off,
    });
    final shuffling = mode == PlaybackMode.shuffle;
    if (shuffling) await _player.shuffle();
    await _player.setShuffleModeEnabled(shuffling);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
    await play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(processingState: AudioProcessingState.idle),
    );
    return super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        // Previous / play-pause / next in the collapsed notification.
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }
}
