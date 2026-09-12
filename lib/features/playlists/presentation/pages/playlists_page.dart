import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/bilingual_text.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../domain/entities/playlist.dart';
import '../bloc/playlist_bloc.dart';
import '../widgets/playlist_cover.dart';
import '../widgets/playlist_name_dialog.dart';

/// The Playlists tab: the user's saved lists, newest-updated first.
class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            if (state is! PlaylistsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final header = BilingualHeader(
              sinhala: bi.si.playlistsTitle,
              english: bi.en.playlistsTitle,
              englishSuffix: state.playlists.isEmpty
                  ? null
                  : bi.en.playlistsCount(state.playlists.length),
            );

            if (state.playlists.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(
                    child: EmptyState(
                      sinhalaTitle: bi.si.playlistsEmptyTitle,
                      englishTitle: bi.en.playlistsEmptyTitle,
                      subtitle: bi.primary.playlistsEmptySubtitle,
                      action: FilledButton.icon(
                        onPressed: () => _create(context),
                        icon: const Icon(Icons.add),
                        label: Text(bi.primary.playlistCreate),
                      ),
                    ),
                  ),
                ],
              );
            }

            // The catalogue supplies the covers the collage is built from;
            // it is already loaded by the time this tab is reachable.
            return CatalogueLoadedBuilder(
              builder: (context, catalogue) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: state.playlists.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final playlist = state.playlists[index];
                          return _PlaylistTile(
                            playlist: playlist,
                            coverUrls: [
                              for (final item
                                  in catalogue.byIds(playlist.pirithIds))
                                item.coverUrl,
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          // The empty state already offers a create button; a FAB on top of
          // it would ask the same question twice.
          if (state is! PlaylistsLoaded || state.playlists.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _create(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final bloc = context.read<PlaylistBloc>();
    final result = await showPlaylistNameDialog(
      context,
      title: Bilingual.read(context).primary.playlistCreateTitle,
    );
    if (result == null) return;
    bloc.add(
      PlaylistCreated(name: result.name, description: result.description),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({required this.playlist, required this.coverUrls});

  final Playlist playlist;
  final List<String> coverUrls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bi = Bilingual.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: PlaylistCover(
          playlistId: playlist.id,
          coverUrls: coverUrls,
          size: 56,
        ),
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sinhalaTitle(
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          playlist.description.isEmpty
              ? bi.primary.playlistItemCount(playlist.itemCount)
              : '${bi.primary.playlistItemCount(playlist.itemCount)} · ${playlist.description}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            context.push(AppRoutePaths.playlistDetailsFor(playlist.id)),
      ),
    );
  }
}
