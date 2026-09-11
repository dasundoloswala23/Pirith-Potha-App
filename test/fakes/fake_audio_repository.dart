import 'dart:async';

import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/player/domain/entities/playback_mode.dart';
import 'package:pitithpotha/features/player/domain/entities/playback_status.dart';
import 'package:pitithpotha/features/player/domain/repositories/audio_repository.dart';

/// In-memory [AudioRepository] fake for widget/BLoC tests, so tests don't
/// need a live audio_service/just_audio connection to exercise
/// [PlayerBloc].
///
/// Queue advance is modelled the same way the real player behaves: moving
/// to another item emits on [currentIndexStream], which is what the BLoC
/// listens to. [completeCurrent] simulates a track ending so auto-advance
/// can be tested at all — the real completion path is otherwise impossible
/// to reach from a test.
class FakeAudioRepository implements AudioRepository {
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _indexController = StreamController<int>.broadcast();

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
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<int> get currentIndexStream => _indexController.stream;

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
    _durationController.add(Duration(seconds: _queue[_index].duration));
    _statusController.add(PlaybackStatus.playing);
  }

  @override
  Future<void> skipToNext() async => _moveTo(_nextIndex());

  @override
  Future<void> skipToPrevious() async =>
      _moveTo(_index > 0 ? _index - 1 : _queue.length - 1);

  @override
  Future<void> skipToIndex(int index) async => _moveTo(index);

  @override
  Future<void> setMode(PlaybackMode mode) async => _mode = mode;

  /// Simulates the current track finishing, advancing the way the real
  /// player would for the active [mode].
  void completeCurrent() {
    switch (_mode) {
      case PlaybackMode.repeatOne:
        _statusController.add(PlaybackStatus.playing);
      case PlaybackMode.normal when _index >= _queue.length - 1:
        _statusController.add(PlaybackStatus.completed);
      case PlaybackMode.normal:
      case PlaybackMode.repeatAll:
      case PlaybackMode.shuffle:
        _moveTo(_nextIndex());
    }
  }

  int _nextIndex() => _index >= _queue.length - 1 ? 0 : _index + 1;

  void _moveTo(int index) {
    if (index < 0 || index >= _queue.length) return;
    _index = index;
    _indexController.add(index);
    _statusController.add(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async => _statusController.add(PlaybackStatus.paused);

  @override
  Future<void> resume() async => _statusController.add(PlaybackStatus.playing);

  @override
  Future<void> seekTo(Duration position) async =>
      _positionController.add(position);

  @override
  Future<void> stop() async {
    _queue = const [];
    _index = 0;
    _statusController.add(PlaybackStatus.paused);
  }
}
