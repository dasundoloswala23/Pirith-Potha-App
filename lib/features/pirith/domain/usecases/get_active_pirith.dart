import '../entities/pirith_entity.dart';
import '../repositories/pirith_repository.dart';

class GetActivePirith {
  const GetActivePirith(this._repository);

  final PirithRepository _repository;

  Future<List<PirithEntity>> call() => _repository.getActivePirith();
}
