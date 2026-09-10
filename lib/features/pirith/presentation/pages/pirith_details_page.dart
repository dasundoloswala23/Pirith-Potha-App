import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../downloads/domain/entities/download_entity.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../domain/entities/pirith_entity.dart';
import '../bloc/catalogue_bloc.dart';
import '../widgets/pirith_artwork.dart';

/// Real Pirith details, sourced from the already-loaded catalogue. Play
/// starts real playback via [PlayerBloc] and opens the full player;
/// Download/Favorite are still placeholders — those land in Phase 6/7 (see
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
                            onPressed: () {
                              context.read<PlayerBloc>().add(PlayerPlayRequested(item));
                              context.push(AppRoutePaths.player);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.actionPlay),
                          ),
                          const SizedBox(width: 12),
                          _DetailsDownloadButton(item: item),
                          const SizedBox(width: 12),
                          IconButton.outlined(
                            onPressed: () => _comingSoon(context, l10n),
                            icon: const Icon(Icons.favorite_outline),
                            tooltip: l10n.actionAddFavorite,
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty || item.descriptionSinhala.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.pirithDescriptionLabel,
                            style: AppTypography.sinhalaTitle(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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

class _DetailsDownloadButton extends StatelessWidget {
  const _DetailsDownloadButton({required this.item});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entry = context.select<DownloadBloc, DownloadEntity?>((bloc) {
      final state = bloc.state;
      return state is DownloadsLoaded ? state.statusFor(item.id) : null;
    });

    switch (entry?.status) {
      case DownloadStatus.downloading:
        return OutlinedButton.icon(
          onPressed: () => context.read<DownloadBloc>().add(DownloadCancelRequested(item.id)),
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, value: entry!.progress),
          ),
          label: Text(l10n.downloadInProgress),
        );
      case DownloadStatus.downloaded:
        return OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, l10n),
          icon: const Icon(Icons.download_done),
          label: Text(l10n.downloadedLabel),
        );
      case DownloadStatus.failed:
        return OutlinedButton.icon(
          onPressed: () => context.read<DownloadBloc>().add(DownloadRequested(item)),
          icon: const Icon(Icons.error_outline),
          label: Text(l10n.actionRetry),
        );
      case DownloadStatus.notDownloaded:
      case null:
        return OutlinedButton.icon(
          onPressed: () => context.read<DownloadBloc>().add(DownloadRequested(item)),
          icon: const Icon(Icons.download_outlined),
          label: Text(l10n.actionDownload),
        );
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.downloadDeleteConfirmTitle),
        content: Text(l10n.downloadDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DownloadBloc>().add(DownloadDeleteRequested(item.id));
    }
  }
}
