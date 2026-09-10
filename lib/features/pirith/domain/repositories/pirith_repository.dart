import '../entities/category_entity.dart';
import '../entities/pirith_entity.dart';

/// Catalogue abstraction the domain/presentation layers depend on. The
/// Firestore implementation lives in the data layer — see
/// docs/02_architecture.md. Only active, published content is ever
/// returned (see docs/03_database_schema.md — `isActive` is the publish
/// flag admins control).
abstract interface class PirithRepository {
  Future<List<CategoryEntity>> getCategories();

  /// All active Pirith, ordered by `sortOrder`. Used as the single source
  /// for Home (featured/popular sections), Search (client-side filter),
  /// and category listings — the catalogue is small enough for MVP that a
  /// full fetch is simpler and cheaper than several separate queries.
  Future<List<PirithEntity>> getActivePirith();

  Future<PirithEntity> getPirithById(String id);
}
