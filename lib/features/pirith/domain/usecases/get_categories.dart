import '../entities/category_entity.dart';
import '../repositories/pirith_repository.dart';

class GetCategories {
  const GetCategories(this._repository);

  final PirithRepository _repository;

  Future<List<CategoryEntity>> call() => _repository.getCategories();
}
