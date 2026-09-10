import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/pirith_model.dart';

/// Caches the last successfully-fetched catalogue on disk so the app keeps
/// working offline after the first successful load — see
/// docs/02_architecture.md's offline-first repository pattern and
/// docs/05_offline_download.md (a downloaded Pirith must show its real
/// title/description with zero network, which needs the catalogue itself
/// to survive being offline, not just the audio file).
class PirithLocalDataSource {
  PirithLocalDataSource(this._prefs);

  static const _categoriesKey = 'cached_categories';
  static const _pirithKey = 'cached_pirith';

  final SharedPreferences _prefs;

  Future<void> cacheCategories(List<CategoryModel> categories) {
    final json = jsonEncode(categories.map((c) => c.toJson()).toList());
    return _prefs.setString(_categoriesKey, json);
  }

  List<CategoryModel>? getCachedCategories() {
    final raw = _prefs.getString(_categoriesKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cachePirith(List<PirithModel> pirith) {
    final json = jsonEncode(pirith.map((p) => p.toJson()).toList());
    return _prefs.setString(_pirithKey, json);
  }

  List<PirithModel>? getCachedPirith() {
    final raw = _prefs.getString(_pirithKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => PirithModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
