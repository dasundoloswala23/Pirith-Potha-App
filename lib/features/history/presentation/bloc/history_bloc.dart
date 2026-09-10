import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

part 'history_event.dart';
part 'history_state.dart';

/// App-scoped BLoC (one instance for the whole app) mirroring the on-disk
/// recently-played history — see docs/09_development_roadmap.md (Phase 7).
/// Recording a play happens in [PlayerBloc], not here — this BLoC only
/// reflects state for the Home "Recently Played" section and its screen.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required HistoryRepository historyRepository})
      : _historyRepository = historyRepository,
        super(const HistoryLoading()) {
    on<_HistoryChanged>((event, emit) => emit(HistoryLoaded(event.entries)));

    add(_HistoryChanged(_historyRepository.currentHistory));
    _subscription = _historyRepository.historyStream.listen(
      (entries) => add(_HistoryChanged(entries)),
    );
  }

  final HistoryRepository _historyRepository;

  late final StreamSubscription<List<HistoryEntry>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
