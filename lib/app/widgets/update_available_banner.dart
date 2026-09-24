import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_urls.dart';
import '../../core/firebase/analytics_service.dart';
import '../../core/l10n/bilingual.dart';
import '../../core/services/external_link_launcher.dart';
import '../../core/utils/app_version.dart';
import '../../features/app_update/domain/entities/version_config.dart';
import '../../features/app_update/domain/repositories/version_config_repository.dart';
import '../theme/app_spacing.dart';

/// Dismissible "a newer version exists" card — the only update signal iOS
/// ever gets (Apple has no in-app-update API), and on Android a visible
/// nudge for the gap between a flexible download finishing and the user
/// actually tapping restart.
///
/// Renders nothing until a version check completes and finds something
/// worth showing, so it costs nothing on the common "already current" path.
///
/// "Later" is remembered against the *remote* version that was dismissed,
/// not the installed one — a dismissal doesn't suppress a genuinely newer
/// release published afterwards.
class UpdateAvailableBanner extends StatefulWidget {
  const UpdateAvailableBanner({super.key});

  @override
  State<UpdateAvailableBanner> createState() => _UpdateAvailableBannerState();
}

class _UpdateAvailableBannerState extends State<UpdateAvailableBanner> {
  static const _dismissedVersionKey = 'update_banner_dismissed_version';

  VersionConfig? _outdatedConfig;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Best-effort: a failure anywhere here just means no banner, never a
    // crash or an error shown to the user — same standard as
    // VersionConfigRepositoryImpl's own swallow-and-report.
    try {
      if (!GetIt.instance.isRegistered<VersionConfigRepository>()) return;

      final config = await GetIt.instance<VersionConfigRepository>()
          .getVersionConfig();
      if (config == null || !mounted) return;

      final installed = (await PackageInfo.fromPlatform()).version;
      if (!isOutdated(installed: installed, latest: config.latestVersion)) {
        return;
      }

      final prefs = GetIt.instance<SharedPreferences>();
      if (prefs.getString(_dismissedVersionKey) == config.latestVersion) {
        return;
      }

      if (GetIt.instance.isRegistered<AnalyticsService>()) {
        unawaited(
          GetIt.instance<AnalyticsService>()
              .logUpdateBannerShown(config.latestVersion),
        );
      }
      setState(() => _outdatedConfig = config);
    } catch (_) {
      // Nothing to show is the safe outcome of any failure here.
    }
  }

  void _dismiss(VersionConfig config) {
    GetIt.instance<SharedPreferences>()
        .setString(_dismissedVersionKey, config.latestVersion);
    if (GetIt.instance.isRegistered<AnalyticsService>()) {
      unawaited(
        GetIt.instance<AnalyticsService>().logUpdateDismissed(config.latestVersion),
      );
    }
    setState(() => _outdatedConfig = null);
  }

  void _update(VersionConfig config) {
    if (GetIt.instance.isRegistered<AnalyticsService>()) {
      unawaited(
        GetIt.instance<AnalyticsService>().logUpdateAccepted(config.latestVersion),
      );
    }

    // iOS has no numbered Play package id to link to; until AppUrls.appStoreId
    // is filled in (see its doc comment) there is nowhere to send an iOS user,
    // so the button quietly does nothing rather than open a broken link.
    if (!kIsWeb && Platform.isIOS) {
      if (AppUrls.appStoreId.isEmpty) return;
      launchExternalUrl('https://apps.apple.com/app/id${AppUrls.appStoreId}');
      return;
    }
    launchExternalUrl(AppUrls.playStoreListing);
  }

  @override
  Widget build(BuildContext context) {
    final config = _outdatedConfig;
    if (config == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bi = Bilingual.of(context);
    final blurb = bi.sinhalaFirst
        ? config.updateMessageSinhala
        : config.updateMessageEnglish;

    return Material(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.system_update_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bi.primary.updateBannerTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    blurb.isNotEmpty
                        ? blurb
                        : bi.primary.updateBannerBody(config.latestVersion),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _dismiss(config),
              child: Text(bi.primary.updateBannerActionLater),
            ),
            FilledButton(
              onPressed: () => _update(config),
              child: Text(bi.primary.updateBannerActionUpdate),
            ),
          ],
        ),
      ),
    );
  }
}
