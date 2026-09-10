part of 'player_bloc.dart';

sealed class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerPlayRequested extends PlayerEvent {
  const PlayerPlayRequested(this.item);

  final PirithEntity item;

  @override
  List<Object?> get props => [item];
}

class PlayerPauseRequested extends PlayerEvent {
  const PlayerPauseRequested();
}

class PlayerResumeRequested extends PlayerEvent {
  const PlayerResumeRequested();
}

class PlayerSeekRequested extends PlayerEvent {
  const PlayerSeekRequested(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class PlayerStopRequested extends PlayerEvent {
  const PlayerStopRequested();
}

class _PlayerStatusChanged extends PlayerEvent {
  const _PlayerStatusChanged(this.status);

  final PlaybackStatus status;

  @override
  List<Object?> get props => [status];
}

class _PlayerPositionChanged extends PlayerEvent {
  const _PlayerPositionChanged(this.position);

  final Duration position;

  @override
  List<Object?> get props => [position];
}

class _PlayerDurationChanged extends PlayerEvent {
  const _PlayerDurationChanged(this.duration);

  final Duration? duration;

  @override
  List<Object?> get props => [duration];
}
