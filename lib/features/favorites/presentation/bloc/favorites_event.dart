part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class FavoriteToggled extends FavoritesEvent {
  const FavoriteToggled(this.pirithId);

  final String pirithId;

  @override
  List<Object?> get props => [pirithId];
}

class _FavoriteIdsChanged extends FavoritesEvent {
  const _FavoriteIdsChanged(this.ids);

  final List<String> ids;

  @override
  List<Object?> get props => [ids];
}
