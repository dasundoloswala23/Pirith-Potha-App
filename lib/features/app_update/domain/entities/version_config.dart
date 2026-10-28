import 'package:equatable/equatable.dart';

/// The `config/app_meta` Firestore doc: the version the store listing
/// actually carries, so the app can tell an out-of-date install apart from
/// a current one without an API that can answer that on Android's behalf
/// (there isn't one on iOS at all).
class VersionConfig extends Equatable {
  const VersionConfig({
    required this.latestVersion,
    this.updateMessageEnglish = '',
    this.updateMessageSinhala = '',
    this.releaseNotesEnglish = '',
    this.releaseNotesSinhala = '',
  });

  /// Dotted version string matching this app's own `versionName`
  /// (`pubspec.yaml`'s `version:` before the `+build`), e.g. `"1.00.03"`.
  ///
  /// Only raise this once that build is live on the store: a minor/major
  /// bump makes the update mandatory, and pointing it at a version users
  /// can't download yet locks them out.
  final String latestVersion;

  final String updateMessageEnglish;
  final String updateMessageSinhala;
  final String releaseNotesEnglish;
  final String releaseNotesSinhala;

  @override
  List<Object?> get props => [
    latestVersion,
    updateMessageEnglish,
    updateMessageSinhala,
    releaseNotesEnglish,
    releaseNotesSinhala,
  ];
}
