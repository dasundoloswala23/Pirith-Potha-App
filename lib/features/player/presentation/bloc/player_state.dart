part of 'player_bloc.dart';

sealed class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

/// Nothing has ever been played this session.
class PlayerIdle extends PlayerState {
  const PlayerIdle();
}

class PlayerActive extends PlayerState {
  const PlayerActive({
    required this.item,
    required this.status,
    required this.position,
    required this.duration,
  });

  final PirithEntity item;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;

  bool get isPlaying => status == PlaybackStatus.playing;

  PlayerActive copyWith({
    PirithEntity? item,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerActive(
      item: item ?? this.item,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [item, status, position, duration];
}
