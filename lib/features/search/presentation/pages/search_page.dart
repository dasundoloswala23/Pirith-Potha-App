import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/pirith_mark.dart';

/// Placeholder search screen. Real search is wired up in Phase 4 (Pirith
/// Catalogue) — see docs/09_development_roadmap.md.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.searchHint,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PirithMark(
              size: 56,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(l10n.comingSoon),
          ],
        ),
      ),
    );
  }
}
