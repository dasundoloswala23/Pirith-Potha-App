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
    this.queue = const [],
    this.queueIndex = 0,
    this.mode = PlaybackMode.normal,
  });

  final PirithEntity item;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;

  /// The full playback queue. A single Pirith is a queue of one, so the UI
  /// doesn't need a separate "no queue" case.
  final List<PirithEntity> queue;
  final int queueIndex;
  final PlaybackMode mode;

  bool get isPlaying => status == PlaybackStatus.playing;

  /// Skip is offered whenever there's more than one item: with repeat on,
  /// the ends wrap, so there is always somewhere to go.
  bool get hasNext =>
      queue.length > 1 &&
      (mode != PlaybackMode.normal || queueIndex < queue.length - 1);

  bool get hasPrevious =>
      queue.length > 1 && (mode != PlaybackMode.normal || queueIndex > 0);

  PlayerActive copyWith({
    PirithEntity? item,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    List<PirithEntity>? queue,
    int? queueIndex,
    PlaybackMode? mode,
  }) {
    return PlayerActive(
      item: item ?? this.item,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => [
    item,
    status,
    position,
    duration,
    queue,
    queueIndex,
    mode,
  ];
}
