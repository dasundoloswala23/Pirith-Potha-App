import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/history/domain/usecases/record_played.dart';
import 'package:pitithpotha/features/history/presentation/bloc/history_bloc.dart';

import '../../fakes/fake_history_repository.dart';

void main() {
  group('HistoryBloc', () {
    test('starts with an empty loaded state', () async {
      final repository = FakeHistoryRepository();
      final bloc = HistoryBloc(historyRepository: repository);
      addTearDown(bloc.close);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final state = bloc.state as HistoryLoaded;
      expect(state.entries, isEmpty);
    });

    test('reflects a recorded play, most-recent first', () async {
      final repository = FakeHistoryRepository();
      final bloc = HistoryBloc(historyRepository: repository);
      addTearDown(bloc.close);
      final recordPlayed = RecordPlayed(repository);

      final future = expectLater(
        bloc.stream,
        emitsThrough(
          isA<HistoryLoaded>().having(
            (s) => s.entries.map((e) => e.pirithId),
            'pirithIds',
            ['2', '1'],
          ),
        ),
      );
      await recordPlayed('1');
      await recordPlayed('2');
      await future;
    });
  });
}
