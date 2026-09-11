import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'player_bloc.dart';

/// Pauses playback after a chosen number of minutes.
///
/// App-scoped rather than owned by the player screen: the whole point is to
/// fall asleep listening, so the timer has to keep running once the screen
/// is closed and the app is backgrounded.
///
/// It coordinates at the presentation layer only — it asks [PlayerBloc] to
/// pause and never touches the audio stack itself, per the architecture
/// rules in CLAUDE.md.
class SleepTimerCubit extends Cubit<int?> {
  SleepTimerCubit(this._playerBloc) : super(null);

  final PlayerBloc _playerBloc;
  Timer? _timer;

  /// Minutes remaining, or null when no timer is set.
  int? get minutes => state;

  void setMinutes(int? value) {
    _timer?.cancel();
    emit(value);
    if (value == null) return;

    _timer = Timer(Duration(minutes: value), () {
      _playerBloc.add(const PlayerPauseRequested());
      if (!isClosed) emit(null);
    });
  }

  void cancel() => setMinutes(null);

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
