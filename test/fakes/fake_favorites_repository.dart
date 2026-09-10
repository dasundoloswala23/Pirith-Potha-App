import 'dart:async';

import 'package:pitithpotha/features/favorites/domain/repositories/favorites_repository.dart';

/// In-memory [FavoritesRepository] fake for widget/BLoC tests.
class FavoritesRepositoryFake implements FavoritesRepository {
  List<String> _ids = [];
  final _controller = StreamController<List<String>>.broadcast();

  @override
  Stream<List<String>> get favoriteIdsStream => _controller.stream;

  @override
  List<String> get currentFavoriteIds => List.unmodifiable(_ids);

  @override
  bool isFavorite(String pirithId) => _ids.contains(pirithId);

  @override
  Future<void> toggleFavorite(String pirithId) async {
    _ids = _ids.contains(pirithId)
        ? _ids.where((id) => id != pirithId).toList()
        : [pirithId, ..._ids];
    _controller.add(List.unmodifiable(_ids));
  }
}
