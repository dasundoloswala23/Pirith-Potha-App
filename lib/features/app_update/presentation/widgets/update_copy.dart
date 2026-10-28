import '../../../../core/l10n/bilingual.dart';
import '../../domain/entities/version_config.dart';

/// Picks the remote message and release notes in the leading language,
/// falling back to the other language, then to the built-in default — the
/// admin may fill in one language, both, or neither.
class UpdateCopy {
  UpdateCopy(this.config, this.bi, {required this.mandatory});

  final VersionConfig config;
  final Bilingual bi;
  final bool mandatory;

  String get message {
    final remote = _pick(config.updateMessageSinhala, config.updateMessageEnglish);
    if (remote.isNotEmpty) return remote;
    return mandatory
        ? bi.primary.updateMandatoryBody
        : bi.primary.updateOptionalBody;
  }

  String get releaseNotes =>
      _pick(config.releaseNotesSinhala, config.releaseNotesEnglish);

  String _pick(String sinhala, String english) {
    final (first, second) = bi.order(sinhala, english);
    return first.isNotEmpty ? first : second;
  }
}
