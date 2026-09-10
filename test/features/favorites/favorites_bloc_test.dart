import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/favorites/domain/usecases/toggle_favorite.dart';
import 'package:pitithpotha/features/favorites/presentation/bloc/favorites_bloc.dart';

import '../../fakes/fake_favorites_repository.dart';

FavoritesBloc _buildBloc(FavoritesRepositoryFake repository) => FavoritesBloc(
      favoritesRepository: repository,
      toggleFavorite: ToggleFavorite(repository),
    );

void main() {
  group('FavoritesBloc', () {
    test('starts with an empty loaded state', () async {
      final repository = FavoritesRepositoryFake();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final state = bloc.state as FavoritesLoaded;
      expect(state.ids, isEmpty);
    });

    test('toggling adds then removes an id, most-recent first', () async {
      final repository = FavoritesRepositoryFake();
      final bloc = _buildBloc(repository);
      addTearDown(bloc.close);

      final addFuture = expectLater(
        bloc.stream,
        emitsThrough(isA<FavoritesLoaded>().having((s) => s.ids, 'ids', ['1'])),
      );
      bloc.add(const FavoriteToggled('1'));
      await addFuture;

      final addSecondFuture = expectLater(
        bloc.stream,
        emitsThrough(isA<FavoritesLoaded>().having((s) => s.ids, 'ids', ['2', '1'])),
      );
      bloc.add(const FavoriteToggled('2'));
      await addSecondFuture;

      final removeFuture = expectLater(
        bloc.stream,
        emitsThrough(isA<FavoritesLoaded>().having((s) => s.ids, 'ids', ['2'])),
      );
      bloc.add(const FavoriteToggled('1'));
      await removeFuture;
    });
  });
}
