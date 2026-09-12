import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/bilingual.dart';
import '../bloc/playlist_bloc.dart';
import 'playlist_name_dialog.dart';

/// Bottom sheet listing every playlist with a tick beside the ones already
/// holding this Pirith. Tapping toggles membership, so the sheet both adds
/// and corrects a mistaken add without a second gesture to discover.
///
/// The first row creates a new playlist and adds the Pirith to it in one
/// step, which is the common case the first few times a user meets this.
Future<void> showAddToPlaylistSheet(
  BuildContext context, {
  required String pirithId,
  required String pirithTitle,
}) {
  final theme = Theme.of(context);
  // [Bilingual.read], not [Bilingual.of]: this function runs from a tap
  // handler, where watching a provider asserts. Resolving it here also
  // keeps it out of the sheet builder, which runs under the root navigator
  // and outside this subtree's providers.
  final bi = Bilingual.read(context);
  final bloc = context.read<PlaylistBloc>();
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: theme.colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => SafeArea(
      child: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            final playlists = state is PlaylistsLoaded
                ? state.playlists
                : const [];

            return ConstrainedBox(
              // Never taller than half the screen: the sheet is a chooser,
              // not a screen, and the Pirith being added stays visible
              // behind it.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        Text(
                          bi.primary.playlistAddTo,
                          textAlign: TextAlign.center,
                          style: AppTypography.sinhalaTitle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          pirithTitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(bi.si.playlistCreate),
                    subtitle: Text(bi.en.playlistCreate),
                    onTap: () async {
                      final result = await showPlaylistNameDialog(
                        sheetContext,
                        title: bi.primary.playlistCreateTitle,
                      );
                      if (result == null) return;
                      bloc.add(
                        PlaylistCreated(
                          name: result.name,
                          description: result.description,
                          initialPirithId: pirithId,
                        ),
                      );
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(bi.primary.playlistAddedTo(result.name)),
                        ),
                      );
                    },
                  ),
                  if (playlists.isNotEmpty) const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final contains = playlist.pirithIds.contains(pirithId);

                        return ListTile(
                          title: Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            bi.primary.playlistItemCount(playlist.itemCount),
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: contains
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.goldDark,
                                )
                              : const Icon(Icons.add_circle_outline),
                          onTap: () {
                            bloc.add(
                              contains
                                  ? PlaylistItemRemoved(
                                      playlistId: playlist.id,
                                      pirithId: pirithId,
                                    )
                                  : PlaylistItemAdded(
                                      playlistId: playlist.id,
                                      pirithId: pirithId,
                                    ),
                            );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  contains
                                      ? bi.primary.playlistRemovedFrom(playlist.name)
                                      : bi.primary.playlistAddedTo(playlist.name),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
