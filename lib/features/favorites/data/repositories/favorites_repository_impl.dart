import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._prefs);

  static const _key = 'favorite_pirith_ids';

  final SharedPreferences _prefs;
  final _controller = StreamController<List<String>>.broadcast();

  List<String> _ids = [];

  Future<void> initialize() async {
    _ids = _prefs.getStringList(_key) ?? [];
  }

  @override
  Stream<List<String>> get favoriteIdsStream => _controller.stream;

  @override
  List<String> get currentFavoriteIds => List.unmodifiable(_ids);

  @override
  bool isFavorite(String pirithId) => _ids.contains(pirithId);

  @override
  Future<void> toggleFavorite(String pirithId) async {
    if (_ids.contains(pirithId)) {
      _ids = _ids.where((id) => id != pirithId).toList();
    } else {
      _ids = [pirithId, ..._ids];
    }
    await _prefs.setStringList(_key, _ids);
    _controller.add(List.unmodifiable(_ids));
  }
}
