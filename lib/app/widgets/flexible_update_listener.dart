import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/firebase/analytics_service.dart';
import '../../core/l10n/bilingual.dart';
import '../../core/services/app_update_service.dart';

/// Shows the "restart to finish updating" [MaterialBanner] once Android's
/// flexible in-app update has finished downloading in the background.
///
/// A [MaterialBanner] rather than a [SnackBar]: this needs to persist until
/// the user acts on it, the same reasoning [MiniPlayerBar] is a docked
/// persistent widget rather than something transient.
///
/// Wrap the shell's content with this once; it renders nothing until (and
/// unless) a download actually completes this session.
class FlexibleUpdateListener extends StatefulWidget {
  const FlexibleUpdateListener({required this.child, super.key});

  final Widget child;

  @override
  State<FlexibleUpdateListener> createState() =>
      _FlexibleUpdateListenerState();
}

class _FlexibleUpdateListenerState extends State<FlexibleUpdateListener> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = AppUpdateService.onFlexibleUpdateDownloaded.listen(
      (_) => _showBanner(),
    );
  }

  void _showBanner() {
    if (!mounted) return;
    if (GetIt.instance.isRegistered<AnalyticsService>()) {
      unawaited(GetIt.instance<AnalyticsService>().logFlexibleUpdateRestartShown());
    }

    final bi = Bilingual.read(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          content: Text(bi.primary.updateRestartTitle),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                AppUpdateService.completeUpdate();
              },
              child: Text(bi.primary.updateRestartAction),
            ),
          ],
        ),
      );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
