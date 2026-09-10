part of 'history_bloc.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.entries);

  /// Most-recently-played first.
  final List<HistoryEntry> entries;

  @override
  List<Object?> get props => [entries];
}
