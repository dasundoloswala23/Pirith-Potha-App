import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../../pirith/presentation/widgets/catalogue_loaded_builder.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../../pirith/presentation/widgets/pirith_card.dart';
import '../../../player/domain/entities/playback_mode.dart';
import '../../../player/presentation/bloc/player_bloc.dart';
import '../../domain/entities/playlist.dart';
import '../bloc/playlist_bloc.dart';
import '../widgets/playlist_cover.dart';
import '../widgets/playlist_name_dialog.dart';

/// One playlist: its cover, the two play actions, and its Pirith in saved
/// order.
///
/// There is no detail BLoC — the playlist is selected out of
/// [PlaylistsLoaded], so an edit made anywhere (the add-to-playlist sheet,
/// another screen) is reflected here without a second source of truth. If
/// the playlist disappears (deleted from under us) the screen pops.
class PlaylistDetailsPage extends StatefulWidget {
  const PlaylistDetailsPage({required this.playlistId, super.key});

  final String playlistId;

  @override
  State<PlaylistDetailsPage> createState() => _PlaylistDetailsPageState();
}

class _PlaylistDetailsPageState extends State<PlaylistDetailsPage> {
  /// Drag handles and tap-to-play fight each other, so reordering lives
  /// behind an explicit mode rather than being always on.
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final bi = Bilingual.of(context);

    final playlist = context.select<PlaylistBloc, Playlist?>((bloc) {
      final state = bloc.state;
      return state is PlaylistsLoaded ? state.byId(widget.playlistId) : null;
    });

    if (playlist == null) {
      // Either still loading, or deleted from another screen.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Reordering needs two items to be meaningful, but the toggle must
          // survive removing the second one — otherwise the only way out of
          // edit mode is the back button.
          if (playlist.pirithIds.length > 1 || _editing)
            TextButton(
              onPressed: () => setState(() => _editing = !_editing),
              child: Text(_editing ? bi.primary.playlistDone : bi.primary.playlistEdit),
            ),
          PopupMenuButton<_PlaylistAction>(
            onSelected: (action) => _onAction(action, playlist),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _PlaylistAction.rename,
                child: Text(bi.primary.playlistRenameTitle),
              ),
              PopupMenuItem(
                value: _PlaylistAction.delete,
                // A menu item is a label ("Delete"), not the confirm
                // dialog's question ("Delete this playlist?").
                child: Text(bi.primary.actionDelete),
              ),
            ],
          ),
        ],
      ),
      body: CatalogueLoadedBuilder(
        builder: (context, catalogue) {
          final items = catalogue.byIds(playlist.pirithIds);

          if (items.isEmpty) {
            return EmptyState(
              sinhalaTitle: bi.si.playlistEmptyTitle,
              englishTitle: bi.en.playlistEmptyTitle,
              subtitle: bi.primary.playlistEmptySubtitle,
            );
          }

          return Column(
            children: [
              _Header(playlist: playlist, items: items),
              const Divider(height: 1),
              Expanded(
                child: _editing
                    ? _ReorderableItems(playlist: playlist, items: items)
                    : _Items(items: items),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onAction(_PlaylistAction action, Playlist playlist) async {
    final bloc = context.read<PlaylistBloc>();
    // read, not of: this runs from the popup menu's callback, where
    // context.watch asserts.
    final bi = Bilingual.read(context);
    final messenger = ScaffoldMessenger.of(context);

    switch (action) {
      case _PlaylistAction.rename:
        final result = await showPlaylistNameDialog(
          context,
          title: bi.primary.playlistRenameTitle,
          initialName: playlist.name,
          initialDescription: playlist.description,
        );
        if (result == null) return;
        bloc.add(
          PlaylistRenamed(
            id: playlist.id,
            name: result.name,
            description: result.description,
          ),
        );

      case _PlaylistAction.delete:
        final confirmed = await confirmDestructive(
          context,
          title: bi.primary.playlistDeleteConfirmTitle,
          body: bi.primary.playlistDeleteConfirmBody,
          confirmLabel: bi.primary.actionDelete,
        );
        if (!confirmed) return;
        bloc.add(PlaylistDeleted(playlist.id));
        messenger.showSnackBar(
          SnackBar(content: Text(bi.primary.playlistDeleted)),
        );
        if (mounted) context.pop();
    }
  }
}

enum _PlaylistAction { rename, delete }

class _Header extends StatelessWidget {
  const _Header({required this.playlist, required this.items});

  final Playlist playlist;
  final List<PirithEntity> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bi = Bilingual.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          PlaylistCover(
            playlistId: playlist.id,
            coverUrls: [for (final item in items) item.coverUrl],
            size: 140,
            radius: AppRadius.lg,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            playlist.name,
            textAlign: TextAlign.center,
            style: AppTypography.sinhalaTitle(
              fontSize: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (playlist.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              playlist.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            bi.primary.playlistItemCount(items.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _play(context, PlaybackMode.normal),
                icon: const Icon(Icons.play_arrow),
                label: Text(bi.primary.playlistPlayAll),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _play(context, PlaybackMode.shuffle),
                icon: const Icon(Icons.shuffle),
                label: Text(bi.primary.playlistShuffle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shuffle is a *playback* mode, not a reordering: the queue is handed to
  /// the player in saved order and just_audio randomises its own sequence,
  /// so the playlist on disk is untouched.
  void _play(BuildContext context, PlaybackMode mode) {
    context.read<PlayerBloc>().add(PlayerQueueRequested(items, mode: mode));
    context.push(AppRoutePaths.player);
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.items});

  final List<PirithEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        return PirithCard(
          item: items[index],
          // Tapping a row plays the whole playlist from here, not just the
          // one Pirith — that is the point of a playlist.
          onPlay: () {
            context.read<PlayerBloc>().add(
              PlayerQueueRequested(items, startIndex: index),
            );
            context.push(AppRoutePaths.player);
          },
        );
      },
    );
  }
}

/// Edit mode. Deliberately **not** [PirithCard]:
///
/// * a separator widget inside [ReorderableListView] counts as a reorderable
///   child and corrupts the indices, so spacing goes inside each row;
/// * the default `proxyDecorator` wraps the dragged child in an elevated
///   [Material], which double-shadows a [Card].
class _ReorderableItems extends StatelessWidget {
  const _ReorderableItems({required this.playlist, required this.items});

  final Playlist playlist;
  final List<PirithEntity> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: items.length,
      // onReorderItem, not the deprecated onReorder: it reports the item's
      // final index, so neither this screen nor the repository has to
      // re-apply the drag-downwards off-by-one.
      onReorderItem: (oldIndex, newIndex) => context.read<PlaylistBloc>().add(
        PlaylistItemsReordered(
          playlistId: playlist.id,
          oldIndex: oldIndex,
          newIndex: newIndex,
        ),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(Icons.drag_handle),
                ),
              ),
              PirithArtwork(
                pirithId: item.id,
                coverUrl: item.coverUrl,
                size: 40,
                radius: AppRadius.sm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.titleSinhala,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.sinhalaTitle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: Bilingual.of(context).primary.actionRemove,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  context.read<PlaylistBloc>().add(
                    PlaylistItemRemoved(
                      playlistId: playlist.id,
                      pirithId: item.id,
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        Bilingual.read(context).primary.playlistItemRemoved,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
