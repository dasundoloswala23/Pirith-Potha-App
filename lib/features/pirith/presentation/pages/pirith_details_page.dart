import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';

/// Placeholder Pirith details screen. Real content is wired up in Phase 4
/// (Pirith Catalogue) — see docs/09_development_roadmap.md.
class PirithDetailsPage extends StatelessWidget {
  const PirithDetailsPage({required this.pirithId, super.key});

  final String pirithId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(pirithId)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}
