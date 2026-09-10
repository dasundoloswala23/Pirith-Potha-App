import '../repositories/favorites_repository.dart';

class ToggleFavorite {
  const ToggleFavorite(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(String pirithId) => _repository.toggleFavorite(pirithId);
}
