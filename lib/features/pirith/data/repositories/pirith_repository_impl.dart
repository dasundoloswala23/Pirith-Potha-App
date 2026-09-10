import 'dart:async';

import '../../../../core/errors/app_exception.dart';
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
class PirithRepositoryImpl implements PirithRepository {
  PirithRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final PirithRemoteDataSource _remoteDataSource;
  final PirithLocalDataSource _localDataSource;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final categories = await _remoteDataSource.getCategories();
      unawaited(_localDataSource.cacheCategories(categories).catchError((_) {}));
      return categories;
    } catch (e) {
      final cached = _localDataSource.getCachedCategories();
      if (cached != null) return cached;
      throw AppException(mapFirebaseError(e));
    }
  }

  @override
  Future<List<PirithEntity>> getActivePirith() async {
    try {
      final pirith = await _remoteDataSource.getActivePirith();
      unawaited(_localDataSource.cachePirith(pirith).catchError((_) {}));
      return pirith;
    } catch (e) {
      final cached = _localDataSource.getCachedPirith();
      if (cached != null) return cached;
      throw AppException(mapFirebaseError(e));
    }
  }

  @override
  Future<PirithEntity> getPirithById(String id) async {
    try {
      return await _remoteDataSource.getPirithById(id);
    } catch (e) {
      final cached = _localDataSource.getCachedPirith()?.where((p) => p.id == id).firstOrNull;
      if (cached != null) return cached;
      if (e is AppException) rethrow;
      throw AppException(mapFirebaseError(e));
    }
  }
}
