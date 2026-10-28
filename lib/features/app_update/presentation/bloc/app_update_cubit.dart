import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_urls.dart';
import '../../../../core/errors/error_reporter.dart';
import '../../../../core/services/external_link_launcher.dart';
import '../../../../core/utils/app_version.dart';
import '../../domain/entities/version_config.dart';
import '../../domain/repositories/version_config_repository.dart';

part 'app_update_state.dart';

/// The one update system: compares the installed version against
/// `config/app_meta.latestVersion` and decides between nothing, an optional
/// dialog (newer patch) and a blocking screen (newer minor or major) — see
/// [classifyUpdate].
///
/// Fails open throughout. Offline, a missing config doc, a malformed
/// version, or no store to send the user to all mean [UpdateNotRequired]:
/// the worst outcome of a broken check must be "no prompt", never a user
/// locked out of the app.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit({
    required VersionConfigRepository repository,
    Future<String> Function()? installedVersion,
    String? Function()? storeUrl,
    Future<bool> Function(String url)? launchUrl,
  }) : _repository = repository,
       _installedVersion = installedVersion ?? _platformVersion,
       _storeUrl = storeUrl ?? platformStoreUrl,
       _launchUrl = launchUrl ?? launchExternalUrl,
       super(const UpdateUnknown());

  final VersionConfigRepository _repository;
  final Future<String> Function() _installedVersion;
  final String? Function() _storeUrl;
  final Future<bool> Function(String url) _launchUrl;

  bool _checking = false;
  bool _optionalShown = false;

  /// The listing "Update Now" opens on this platform, or null where there
  /// is none — iOS until `AppUrls.appStoreId` is set, and every non-mobile
  /// platform.
  static String? platformStoreUrl() => switch (defaultTargetPlatform) {
    TargetPlatform.android => AppUrls.playStoreListing,
    TargetPlatform.iOS => AppUrls.appStoreListing,
    _ => null,
  };

  static Future<String> _platformVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  /// Opens this platform's store listing; false when there is none or it
  /// couldn't be opened. Opening the store is not the update — see
  /// [recheck].
  Future<bool> openStore() async {
    final url = _storeUrl();
    if (url == null) return false;
    try {
      return await _launchUrl(url);
    } catch (error, stackTrace) {
      reportNonFatal(
        error,
        stackTrace,
        reason: 'Opening store for update failed',
      );
      return false;
    }
  }

  /// Whether the optional dialog may still be shown this launch.
  bool get shouldShowOptional => state is UpdateOptional && !_optionalShown;

  /// Call once the optional dialog is on screen, so it isn't shown again
  /// until the next launch.
  void markOptionalShown() => _optionalShown = true;

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    try {
      emit(await _evaluate());
    } finally {
      _checking = false;
    }
  }

  /// On returning to the app while blocked: re-reads the *installed*
  /// version. Having opened the store is not evidence the update happened —
  /// only a newer installed build is.
  Future<void> recheck() async {
    if (state is! UpdateMandatory) return;
    await check();
  }

  Future<AppUpdateState> _evaluate() async {
    try {
      if (_storeUrl() == null) return const UpdateNotRequired();

      final config = await _repository.getVersionConfig();
      if (config == null) return const UpdateNotRequired();

      final installed = await _installedVersion();
      return switch (classifyUpdate(
        installed: installed,
        latest: config.latestVersion,
      )) {
        UpdateType.none => const UpdateNotRequired(),
        UpdateType.optional => UpdateOptional(config, installed),
        UpdateType.mandatory => UpdateMandatory(config, installed),
      };
    } catch (error, stackTrace) {
      reportNonFatal(error, stackTrace, reason: 'Update check failed');
      return const UpdateNotRequired();
    }
  }
}
