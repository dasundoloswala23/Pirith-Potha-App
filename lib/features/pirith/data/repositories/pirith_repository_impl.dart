import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/firebase_error_mapper.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/pirith_entity.dart';
import '../../domain/repositories/pirith_repository.dart';
import '../datasources/pirith_remote_data_source.dart';

class PirithRepositoryImpl implements PirithRepository {
  PirithRepositoryImpl(this._remoteDataSource);

  final PirithRemoteDataSource _remoteDataSource;

  @override
  Future<List<CategoryEntity>> getCategories() =>
      _run(() => _remoteDataSource.getCategories());

  @override
  Future<List<PirithEntity>> getActivePirith() =>
      _run(() => _remoteDataSource.getActivePirith());

  @override
  Future<PirithEntity> getPirithById(String id) =>
      _run(() => _remoteDataSource.getPirithById(id));

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(mapFirebaseError(e));
    }
  }
}
