import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../history/domain/usecases/record_played.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../domain/entities/playback_status.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/usecases/pause_playback.dart';
import '../../domain/usecases/play_pirith.dart';
import '../../domain/usecases/resume_playback.dart';
import '../../domain/usecases/seek_playback.dart';
import '../../domain/usecases/stop_playback.dart';

part 'player_event.dart';
part 'player_state.dart';

/// App-scoped BLoC (one instance for the whole app, so the mini-player and
/// full player screen always reflect the same "now playing" state) — see
/// docs/04_audio_architecture.md. Single active item only; queue/playlist
/// support is a V1.1 feature.
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc({
    required AudioRepository audioRepository,
    required PlayPirith playPirith,
    required PausePlayback pausePlayback,
    required ResumePlayback resumePlayback,
    required SeekPlayback seekPlayback,
    required StopPlayback stopPlayback,
    required RecordPlayed recordPlayed,
  })  : _audioRepository = audioRepository,
        _playPirith = playPirith,
        _pausePlayback = pausePlayback,
        _resumePlayback = resumePlayback,
        _seekPlayback = seekPlayback,
        _stopPlayback = stopPlayback,
        _recordPlayed = recordPlayed,
        super(const PlayerIdle()) {
    on<PlayerPlayRequested>(_onPlayRequested);
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
  }

  final AudioRepository _audioRepository;
  final PlayPirith _playPirith;
  final PausePlayback _pausePlayback;
  final ResumePlayback _resumePlayback;
  final SeekPlayback _seekPlayback;
  final StopPlayback _stopPlayback;
  final RecordPlayed _recordPlayed;

  late final StreamSubscription<PlaybackStatus> _statusSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;

  Future<void> _onPlayRequested(
    PlayerPlayRequested event,
    Emitter<PlayerState> emit,
  ) async {
    emit(
      PlayerActive(
        item: event.item,
        status: PlaybackStatus.loading,
        position: Duration.zero,
        duration: Duration(seconds: event.item.duration),
      ),
    );
    await _playPirith(event.item);
    unawaited(_recordPlayed(event.item.id));
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
    return super.close();
  }
}
