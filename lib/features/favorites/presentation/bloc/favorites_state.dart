part of 'favorites_bloc.dart';

sealed class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.ids);

  /// Most-recently-favorited first.
  final List<String> ids;

  bool isFavorite(String pirithId) => ids.contains(pirithId);

  @override
  List<Object?> get props => [ids];
}
