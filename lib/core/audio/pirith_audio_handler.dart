import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// The single place in the app that touches `just_audio`/`audio_service`
/// directly — see docs/04_audio_architecture.md. Wraps a `just_audio`
/// player and broadcasts its state through `audio_service` so the OS
/// notification, lock screen, and Bluetooth/headset controls all stay in
/// sync automatically. Everything above [AudioRepositoryImpl] talks to
/// this handler only through the base `AudioHandler` API (play/pause/seek/
/// stop/playMediaItem) plus the two extra streams below.
class PirithAudioHandler extends BaseAudioHandler with SeekHandler {
  PirithAudioHandler(this._player) {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        playbackState.add(
          playbackState.value.copyWith(processingState: AudioProcessingState.error),
        );
      },
    );
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
    });
  }

  final AudioPlayer _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    final url = mediaItem.extras?['audioUrl'] as String?;
    if (url == null || url.isEmpty) return;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
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
    playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.idle));
    return super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.fastForward,
        ],
        systemActions: const {MediaAction.seek},
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
      ),
    );
  }
}
