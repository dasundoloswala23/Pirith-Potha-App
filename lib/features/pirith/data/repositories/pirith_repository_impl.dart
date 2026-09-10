import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_reporter.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/pirith_entity.dart';
import '../../domain/repositories/pirith_repository.dart';
import '../datasources/pirith_local_data_source.dart';
import '../datasources/pirith_remote_data_source.dart';

/// Offline-first: falls back to [PirithLocalDataSource]'s on-disk cache
/// whenever the Firestore fetch fails (no network, etc.), so the catalogue
/// — and therefore downloaded Pirith, favorites, and history, which all
/// resolve titles against it — keeps working with no connection after the
/// first successful load. Only surfaces a [Failure] when both the network
/// call and the cache come up empty (e.g. the very first launch offline).
///
/// An *empty* cache is deliberately not treated as a usable fallback: an
/// early launch caches `[]`, and returning that would turn every later
/// hard failure (missing index, permission denied) into a silent, empty
/// catalogue indistinguishable from "no content published yet".
class PirithRepositoryImpl implements PirithRepository {
  PirithRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final PirithRemoteDataSource _remoteDataSource;
  final PirithLocalDataSource _localDataSource;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final categories = await _remoteDataSource.getCategories();
      unawaited(
        _localDataSource.cacheCategories(categories).catchError((_) {}),
      );
      return categories;
    } catch (e, st) {
      final cached = _cachedCategories();
      if (cached != null && cached.isNotEmpty) {
        reportNonFatal(e, st, reason: 'Category fetch failed — serving cache');
        return cached;
      }
      reportNonFatal(e, st, reason: 'Category fetch failed, no usable cache');
      throw AppException(mapFirebaseError(e));
    }
  }

  @override
  Future<List<PirithEntity>> getActivePirith() async {
    try {
      final pirith = await _remoteDataSource.getActivePirith();
      unawaited(_localDataSource.cachePirith(pirith).catchError((_) {}));
      return pirith;
    } catch (e, st) {
      final cached = _cachedPirith();
      if (cached != null && cached.isNotEmpty) {
        reportNonFatal(e, st, reason: 'Pirith fetch failed — serving cache');
        return cached;
      }
      reportNonFatal(e, st, reason: 'Pirith fetch failed, no usable cache');
      throw AppException(mapFirebaseError(e));
    }
  }

  @override
  Future<PirithEntity> getPirithById(String id) async {
    try {
      return await _remoteDataSource.getPirithById(id);
    } catch (e, st) {
      final cached = _cachedPirith()?.where((p) => p.id == id).firstOrNull;
      if (cached != null) return cached;
      reportNonFatal(e, st, reason: 'Pirith $id fetch failed, not cached');
      if (e is AppException) rethrow;
      throw AppException(mapFirebaseError(e));
    }
  }

  /// Reading the cache happens inside a `catch`, where a corrupt payload
  /// would otherwise escape as a raw `FormatException`/`TypeError` and
  /// bypass the [AppException] mapping entirely.
  List<CategoryEntity>? _cachedCategories() {
    try {
      return _localDataSource.getCachedCategories();
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'Corrupt category cache');
      return null;
    }
  }

  List<PirithEntity>? _cachedPirith() {
    try {
      return _localDataSource.getCachedPirith();
    } catch (e, st) {
      reportNonFatal(e, st, reason: 'Corrupt Pirith cache');
      return null;
    }
  }
}
