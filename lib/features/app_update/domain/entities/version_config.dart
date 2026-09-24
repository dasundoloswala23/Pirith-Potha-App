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
  });

  /// Dotted version string matching this app's own `versionName`
  /// (`pubspec.yaml`'s `version:` before the `+build`), e.g. `"1.00.03"`.
  final String latestVersion;

  final String updateMessageEnglish;
  final String updateMessageSinhala;

  @override
  List<Object?> get props => [
    latestVersion,
    updateMessageEnglish,
    updateMessageSinhala,
  ];
}
