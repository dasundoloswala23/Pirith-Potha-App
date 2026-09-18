import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_reporter.dart';
import '../../../history/domain/usecases/record_played.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/playback_mode.dart';
import '../../domain/entities/playback_status.dart';
import '../../domain/playable_queue.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/pause_playback.dart';
import '../../domain/usecases/play_pirith.dart';
import '../../domain/usecases/play_queue.dart';
import '../../domain/usecases/set_playback_mode.dart';
import '../../domain/usecases/skip_to_next.dart';
import '../../domain/usecases/skip_to_previous.dart';
import '../../domain/usecases/resume_playback.dart';
import '../../domain/usecases/seek_playback.dart';
import '../../domain/usecases/stop_playback.dart';

part 'player_event.dart';
part 'player_state.dart';

/// App-scoped BLoC (one instance for the whole app, so the mini-player and
/// full player screen always reflect the same "now playing" state) — see
/// docs/04_audio_architecture.md.
///
/// Playback is queue-based throughout; a single Pirith is a queue of one.
/// Auto-advance is driven by the player itself via
/// [AudioRepository.currentIndexStream] rather than by this BLoC watching
/// for completion, so the UI follows the audio even when the advance
/// happened from the lock screen.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc({
    required AudioRepository audioRepository,
    required PlayPirith playPirith,
    required PlayQueue playQueue,
    required SkipToNext skipToNext,
    required SkipToPrevious skipToPrevious,
    required SetPlaybackMode setPlaybackMode,
    required PausePlayback pausePlayback,
    required ResumePlayback resumePlayback,
    required SeekPlayback seekPlayback,
    required StopPlayback stopPlayback,
    required RecordPlayed recordPlayed,
  })  : _audioRepository = audioRepository,
        _playPirith = playPirith,
        _playQueue = playQueue,
        _skipToNext = skipToNext,
        _skipToPrevious = skipToPrevious,
        _setPlaybackMode = setPlaybackMode,
        _pausePlayback = pausePlayback,
        _resumePlayback = resumePlayback,
        _seekPlayback = seekPlayback,
        _stopPlayback = stopPlayback,
        _recordPlayed = recordPlayed,
        super(const PlayerIdle()) {
    on<PlayerPlayRequested>(_onPlayRequested);
    on<PlayerQueueRequested>(_onQueueRequested);
    on<PlayerNextRequested>((event, emit) => _skipToNext());
    on<PlayerPreviousRequested>((event, emit) => _skipToPrevious());
    on<PlayerQueueIndexSelected>(
      (event, emit) => _audioRepository.skipToIndex(event.index),
    );
    on<PlayerModeChanged>(_onModeChanged);
    on<_PlayerIndexChanged>(_onIndexChanged);
    on<PlayerPauseRequested>((event, emit) => _pausePlayback());
    on<PlayerResumeRequested>((event, emit) => _resumePlayback());
    on<PlayerSeekRequested>((event, emit) => _seekPlayback(event.position));
    on<PlayerStopRequested>(_onStopRequested);
    on<_PlayerStatusChanged>(_onStatusChanged);
    on<_PlayerPositionChanged>(_onPositionChanged);
    on<_PlayerDurationChanged>(_onDurationChanged);

    _statusSubscription = _audioRepository.statusStream.listen(
      (status) => add(_PlayerStatusChanged(status)),
    );
    _positionSubscription = _audioRepository.positionStream.listen(
      (position) => add(_PlayerPositionChanged(position)),
    );
    _durationSubscription = _audioRepository.durationStream.listen(
      (duration) => add(_PlayerDurationChanged(duration)),
    );
    _indexSubscription = _audioRepository.currentIndexStream.listen(
      (index) => add(_PlayerIndexChanged(index)),
    );
  }

  final AudioRepository _audioRepository;
  final PlayPirith _playPirith;
  final PlayQueue _playQueue;
  final SkipToNext _skipToNext;
  final SkipToPrevious _skipToPrevious;
  final SetPlaybackMode _setPlaybackMode;
  final PausePlayback _pausePlayback;
  final ResumePlayback _resumePlayback;
  final SeekPlayback _seekPlayback;
  final StopPlayback _stopPlayback;
  final RecordPlayed _recordPlayed;

  late final StreamSubscription<PlaybackStatus> _statusSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<int> _indexSubscription;

  Future<void> _onPlayRequested(
    PlayerPlayRequested event,
    Emitter<PlayerState> emit,
  ) async {
    // Return without emitting: an item with no audio must not become the
    // active one. Previously this emitted `loading`, then the handler
    // silently declined to load anything, so the play button span forever
    // and — if something was already playing — the old track kept going
    // under a UI that had already switched to the new item. Returning here
    // is also what keeps that existing playback untouched, which is the
    // behaviour a video-only Pirith needs.
    if (!event.item.hasAudio) return;

    emit(
      PlayerActive(
        item: event.item,
        status: PlaybackStatus.loading,
        position: Duration.zero,
        duration: Duration(seconds: event.item.duration),
        queue: [event.item],
        mode: _audioRepository.mode,
      ),
    );
    await _play(emit, () => _playPirith(event.item));
    unawaited(_recordPlayed(event.item.id));
  }

  Future<void> _onQueueRequested(
    PlayerQueueRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.items.isEmpty) return;
    // Filter before anything counts. The state's queue must be the same list
    // that reaches the player, or the indices reported back by
    // currentIndexStream address a different array than the one they are
    // used to index.
    final playable = playableQueue(event.items, startIndex: event.startIndex);
    if (playable.items.isEmpty) return;

    final start = playable.index;
    final item = playable.items[start];
    // Emitted before awaiting playback so the player appears instantly.
    emit(
      PlayerActive(
        item: item,
        status: PlaybackStatus.loading,
        position: Duration.zero,
        duration: Duration(seconds: item.duration),
        queue: playable.items,
        queueIndex: start,
        mode: event.mode ?? _audioRepository.mode,
      ),
    );
    await _play(
      emit,
      () => _playQueue(playable.items, startIndex: start, mode: event.mode),
    );
    unawaited(_recordPlayed(item.id));
  }

  /// Runs a playback call, surfacing failure as an error status.
  ///
  /// Without this an AppException thrown by the repository escapes the
  /// handler and the state stays on `loading` forever — the spinner that
  /// never resolves.
  Future<void> _play(Emitter<PlayerState> emit, Future<void> Function() run) async {
    try {
      await run();
    } on AppException catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Playback failed');
      final current = state;
      if (current is PlayerActive) {
        emit(current.copyWith(status: PlaybackStatus.error));
      }
    }
  }

  Future<void> _onModeChanged(
    PlayerModeChanged event,
    Emitter<PlayerState> emit,
  ) async {
    final current = state;
    if (current is PlayerActive) emit(current.copyWith(mode: event.mode));
    await _setPlaybackMode(event.mode);
  }

  /// Follows the player to whichever item it moved to — including advances
  /// this BLoC didn't initiate, such as a track ending or a lock-screen
  /// skip. Without this the mini-player would keep showing the previous
  /// chant while the next one played.
  void _onIndexChanged(_PlayerIndexChanged event, Emitter<PlayerState> emit) {
    final current = state;
    if (current is! PlayerActive) return;
    if (event.index < 0 || event.index >= current.queue.length) return;
    if (event.index == current.queueIndex) return;

    final item = current.queue[event.index];
    emit(
      current.copyWith(
        item: item,
        queueIndex: event.index,
        position: Duration.zero,
        duration: Duration(seconds: item.duration),
      ),
    );
    unawaited(_recordPlayed(item.id));
  }

  Future<void> _onStopRequested(
    PlayerStopRequested event,
    Emitter<PlayerState> emit,
  ) async {
    await _stopPlayback();
    emit(const PlayerIdle());
  }

  void _onStatusChanged(_PlayerStatusChanged event, Emitter<PlayerState> emit) {
    final current = state;
    if (current is PlayerActive) {
      emit(current.copyWith(status: event.status));
    }
  }

  void _onPositionChanged(_PlayerPositionChanged event, Emitter<PlayerState> emit) {
    final current = state;
    if (current is PlayerActive) {
      emit(current.copyWith(position: event.position));
    }
  }

  void _onDurationChanged(_PlayerDurationChanged event, Emitter<PlayerState> emit) {
    final current = state;
    if (current is PlayerActive && event.duration != null) {
      emit(current.copyWith(duration: event.duration));
    }
  }

  @override
  Future<void> close() {
    _statusSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _indexSubscription.cancel();
    return super.close();
  }
}
