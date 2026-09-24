import '../entities/version_config.dart';

abstract interface class VersionConfigRepository {
  /// Returns `null` on any failure (missing doc, offline, malformed data) —
  /// there being no update information is not an error the user should ever
  /// see; it just means no banner.
  Future<VersionConfig?> getVersionConfig();
}
