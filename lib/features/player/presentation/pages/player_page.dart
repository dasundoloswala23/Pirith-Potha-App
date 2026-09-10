import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Placeholder full-screen player. Real playback is wired up in Phase 5
/// (Audio Player) via a centralized AudioPlayerManager — see
/// docs/04_audio_architecture.md.
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}
