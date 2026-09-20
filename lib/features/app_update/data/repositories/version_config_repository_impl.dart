import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/error_reporter.dart';
import '../../domain/entities/version_config.dart';
import '../../domain/repositories/version_config_repository.dart';

/// Reads the single `config/app_meta` doc the admin (or, for now, the
/// Firebase console — see docs/11_release_checklist.md) publishes the
/// latest store version to.
///
/// Deliberately not routed through the same server-only + on-disk-cache
/// machinery `PirithRepositoryImpl` uses: an update check that fails
/// offline should just mean "no banner this session," not a retryable
/// error surfaced to the user, so failures here are swallowed and reported
/// non-fatally rather than thrown.
class VersionConfigRepositoryImpl implements VersionConfigRepository {
  VersionConfigRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<VersionConfig?> getVersionConfig() async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('app_meta')
          .get();
      final data = doc.data();
      if (data == null) return null;

      final latestVersion = data['latestVersion'] as String?;
      if (latestVersion == null || latestVersion.trim().isEmpty) return null;

      final message = data['updateMessage'] as Map<String, dynamic>?;
      return VersionConfig(
        latestVersion: latestVersion,
        updateMessageEnglish: (message?['en'] as String?) ?? '',
        updateMessageSinhala: (message?['si'] as String?) ?? '',
      );
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Failed to read version config');
      return null;
    }
  }
}
