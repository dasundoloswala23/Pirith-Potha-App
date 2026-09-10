import '../entities/pirith_entity.dart';
import '../repositories/pirith_repository.dart';

class GetPirithById {
  const GetPirithById(this._repository);

  final PirithRepository _repository;

  Future<PirithEntity> call(String id) => _repository.getPirithById(id);
}
