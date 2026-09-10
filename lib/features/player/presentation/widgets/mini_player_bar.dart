import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../bloc/player_bloc.dart';

/// Persistent mini-player docked above the bottom nav while something is
/// playing/paused — tap expands to [PlayerPage]. Collapses to nothing when
/// [PlayerBloc] is idle. See docs/08_ui_ux.md.
class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerActive) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final progress = state.duration.inMilliseconds == 0
            ? 0.0
            : state.position.inMilliseconds / state.duration.inMilliseconds;

        return Material(
          color: theme.colorScheme.surface,
          child: InkWell(
            onTap: () => context.push(AppRoutePaths.player),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 2,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      PirithArtwork(
                        pirithId: state.item.id,
                        size: 36,
                        radius: 8,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.item.titleSinhala,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sinhalaTitle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              state.item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          state.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () => context.read<PlayerBloc>().add(
                          state.isPlaying
                              ? const PlayerPauseRequested()
                              : const PlayerResumeRequested(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
