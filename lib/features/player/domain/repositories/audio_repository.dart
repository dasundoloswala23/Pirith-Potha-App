import '../../../pirith/domain/entities/pirith_entity.dart';
import '../entities/playback_status.dart';

/// Audio playback abstraction the domain/presentation layers depend on.
/// The centralized `PirithAudioHandler` (just_audio + audio_service) lives
/// behind [AudioRepositoryImpl] in the data layer — see
/// docs/04_audio_architecture.md. Single "now playing" item only; queue/
/// playlist support is a V1.1 feature per docs/01_product_requirements.md.
abstract interface class AudioRepository {
  Stream<PlaybackStatus> get statusStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;

  PirithEntity? get currentItem;

  Future<void> play(PirithEntity item);
  Future<void> pause();
  Future<void> resume();
  Future<void> seekTo(Duration position);
  Future<void> stop();
}
