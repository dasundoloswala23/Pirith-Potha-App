part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class _HistoryChanged extends HistoryEvent {
  const _HistoryChanged(this.entries);

  final List<HistoryEntry> entries;

  @override
  List<Object?> get props => [entries];
}
