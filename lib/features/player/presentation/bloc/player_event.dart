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

/// Plays a whole queue — a playlist, a category listing, or search
/// results — starting at [startIndex].
class PlayerQueueRequested extends PlayerEvent {
  const PlayerQueueRequested(this.items, {this.startIndex = 0, this.mode});

  final List<PirithEntity> items;
  final int startIndex;
  final PlaybackMode? mode;

  @override
  List<Object?> get props => [items, startIndex, mode];
}

class PlayerNextRequested extends PlayerEvent {
  const PlayerNextRequested();
}

class PlayerPreviousRequested extends PlayerEvent {
  const PlayerPreviousRequested();
}

class PlayerModeChanged extends PlayerEvent {
  const PlayerModeChanged(this.mode);

  final PlaybackMode mode;

  @override
  List<Object?> get props => [mode];
}

class PlayerQueueIndexSelected extends PlayerEvent {
  const PlayerQueueIndexSelected(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
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

/// The player moved to another queue item — including auto-advance we
/// didn't ask for, which is how the UI follows the audio.
class _PlayerIndexChanged extends PlayerEvent {
  const _PlayerIndexChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class _PlayerDurationChanged extends PlayerEvent {
  const _PlayerDurationChanged(this.duration);

  final Duration? duration;

  @override
  List<Object?> get props => [duration];
}
