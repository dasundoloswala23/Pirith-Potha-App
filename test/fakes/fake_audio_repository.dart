import 'dart:async';

import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/player/domain/entities/playback_status.dart';
import 'package:pitithpotha/features/player/domain/repositories/audio_repository.dart';

/// In-memory [AudioRepository] fake for widget/BLoC tests, so tests don't
/// need a live audio_service/just_audio connection to exercise
/// [PlayerBloc].
class FakeAudioRepository implements AudioRepository {
  PirithEntity? _currentItem;
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  @override
  PirithEntity? get currentItem => _currentItem;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Future<void> play(PirithEntity item) async {
    _currentItem = item;
    _durationController.add(Duration(seconds: item.duration));
    _statusController.add(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async => _statusController.add(PlaybackStatus.paused);

  @override
  Future<void> resume() async => _statusController.add(PlaybackStatus.playing);

  @override
  Future<void> seekTo(Duration position) async => _positionController.add(position);

  @override
  Future<void> stop() async {
    _currentItem = null;
    _statusController.add(PlaybackStatus.paused);
  }
}
