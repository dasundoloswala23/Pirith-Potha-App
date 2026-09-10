import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/catalogue_bloc.dart';
import '../widgets/pirith_artwork.dart';

/// Real Pirith details, sourced from the already-loaded catalogue. Play/
/// Download/Favorite are placeholders here — real playback lands in
/// Phase 5, downloads in Phase 6, favorites in Phase 7 (see
/// docs/09_development_roadmap.md).
class PirithDetailsPage extends StatelessWidget {
  const PirithDetailsPage({required this.pirithId, super.key});

  final String pirithId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: BlocBuilder<CatalogueBloc, CatalogueState>(
        builder: (context, state) {
          if (state is! CatalogueLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = state.pirith.where((p) => p.id == pirithId).firstOrNull;
          if (item == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(l10n.comingSoon)),
            );
          }
          final index = state.pirith.indexOf(item);

          return CustomScrollView(
            slivers: [
              SliverAppBar(pinned: true, title: const SizedBox.shrink()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PirithArtwork(index: index, size: 160, radius: 20),
                      const SizedBox(height: 20),
                      Text(
                        item.titleSinhala,
                        textAlign: TextAlign.center,
                        style: AppTypography.sinhalaTitle(
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.title} · ${item.durationLabel()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _comingSoon(context, l10n),
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.actionPlay),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _comingSoon(context, l10n),
                            icon: const Icon(Icons.download_outlined),
                            label: Text(l10n.actionDownload),
                          ),
                          const SizedBox(width: 12),
                          IconButton.outlined(
                            onPressed: () => _comingSoon(context, l10n),
                            icon: const Icon(Icons.favorite_outline),
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty || item.descriptionSinhala.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.descriptionSinhala.isNotEmpty
                                ? item.descriptionSinhala
                                : item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _comingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }
}
