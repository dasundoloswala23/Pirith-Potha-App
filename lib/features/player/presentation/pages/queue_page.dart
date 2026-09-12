import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../bloc/player_bloc.dart';

/// What is queued up to play next.
///
/// This is the *temporary* queue, not a saved playlist: tapping a row jumps
/// the player to it, and closing the screen changes nothing on disk. Playing
/// something else replaces the queue entirely.
class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bi = Bilingual.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(bi.primary.queueTitle)),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          if (state is! PlayerActive || state.queue.isEmpty) {
            // Reachable only from the player, so an empty queue means
            // playback was stopped while this screen was open.
            return const SizedBox.shrink();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: state.queue.length,
            itemBuilder: (context, index) {
              final item = state.queue[index];
              final isCurrent = index == state.queueIndex;

              return ListTile(
                leading: PirithArtwork(
                  pirithId: item.id,
                  coverUrl: item.coverUrl,
                  size: 44,
                  radius: AppRadius.sm,
                ),
                title: Text(
                  item.titleSinhala,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.sinhalaTitle(
                    fontSize: 14,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: isCurrent
                    ? const Icon(Icons.equalizer, color: AppColors.goldDark)
                    : Text(
                        item.durationLabel(),
                        style: theme.textTheme.labelSmall,
                      ),
                onTap: () {
                  context.read<PlayerBloc>().add(
                    PlayerQueueIndexSelected(index),
                  );
                  context.pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}
