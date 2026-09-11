import '../../../pirith/domain/entities/pirith_entity.dart';
import '../entities/playback_mode.dart';
import '../entities/playback_status.dart';

/// Audio playback abstraction the domain/presentation layers depend on.
/// The centralized `PirithAudioHandler` (just_audio + audio_service) lives
/// behind [AudioRepositoryImpl] in the data layer — see
/// docs/04_audio_architecture.md.
///
/// Playback is always queue-based; playing a single Pirith is just a queue
/// of one, so there is one code path rather than two.
abstract interface class AudioRepository {
  Stream<PlaybackStatus> get statusStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  /// Index of the playing item within [queue]. Emits on auto-advance too,
  /// which is how the UI follows the player from one Pirith to the next.
  Stream<int> get currentIndexStream;

  PirithEntity? get currentItem;
  List<PirithEntity> get queue;
  PlaybackMode get mode;

  /// Plays [items] as a queue, starting at [startIndex].
  Future<void> playQueue(
    List<PirithEntity> items, {
    int startIndex = 0,
    PlaybackMode? mode,
  });

  /// Convenience for a queue of one.
  Future<void> play(PirithEntity item);

  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToIndex(int index);
  Future<void> setMode(PlaybackMode mode);

  Future<void> pause();
  Future<void> resume();
  Future<void> seekTo(Duration position);
  Future<void> stop();
}
