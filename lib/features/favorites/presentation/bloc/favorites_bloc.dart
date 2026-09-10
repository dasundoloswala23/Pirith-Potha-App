import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/toggle_favorite.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

/// App-scoped BLoC (one instance for the whole app) so the heart icon on
/// every card/screen reflects the same favorites state — see
/// docs/09_development_roadmap.md (Phase 7).
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required FavoritesRepository favoritesRepository,
    required ToggleFavorite toggleFavorite,
  })  : _favoritesRepository = favoritesRepository,
        _toggleFavorite = toggleFavorite,
        super(const FavoritesLoading()) {
    on<FavoriteToggled>((event, emit) => _toggleFavorite(event.pirithId));
    on<_FavoriteIdsChanged>((event, emit) => emit(FavoritesLoaded(event.ids)));

    add(_FavoriteIdsChanged(_favoritesRepository.currentFavoriteIds));
    _subscription = _favoritesRepository.favoriteIdsStream.listen(
      (ids) => add(_FavoriteIdsChanged(ids)),
    );
  }

  final FavoritesRepository _favoritesRepository;
  final ToggleFavorite _toggleFavorite;

  late final StreamSubscription<List<String>> _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
