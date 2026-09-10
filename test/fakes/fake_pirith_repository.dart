import 'package:pitithpotha/core/errors/app_exception.dart';
import 'package:pitithpotha/core/errors/failure.dart';
import 'package:pitithpotha/features/pirith/domain/entities/category_entity.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/pirith/domain/repositories/pirith_repository.dart';

/// In-memory [PirithRepository] fake for widget/BLoC tests, so tests don't
/// need a live Firestore connection to exercise [CatalogueBloc].
class FakePirithRepository implements PirithRepository {
  FakePirithRepository({
    List<CategoryEntity> categories = const [],
    List<PirithEntity> pirith = const [],
  })  : _categories = categories,
        _pirith = pirith;

  final List<CategoryEntity> _categories;
  final List<PirithEntity> _pirith;

  @override
  Future<List<CategoryEntity>> getCategories() async => _categories;

  @override
  Future<List<PirithEntity>> getActivePirith() async => _pirith;

  @override
  Future<PirithEntity> getPirithById(String id) async {
    final match = _pirith.where((p) => p.id == id).firstOrNull;
    if (match == null) throw const AppException(NotFoundFailure());
    return match;
  }
}
