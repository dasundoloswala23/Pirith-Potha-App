import 'package:pitithpotha/features/app_update/domain/entities/version_config.dart';
import 'package:pitithpotha/features/app_update/domain/repositories/version_config_repository.dart';

class FakeVersionConfigRepository implements VersionConfigRepository {
  FakeVersionConfigRepository([this._config]);

  final VersionConfig? _config;

  @override
  Future<VersionConfig?> getVersionConfig() async => _config;
}
