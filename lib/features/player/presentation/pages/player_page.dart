import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../domain/entities/playback_status.dart';
import '../bloc/player_bloc.dart';

/// Full-screen "now playing" player, driven by the app-scoped [PlayerBloc]
/// — see docs/04_audio_architecture.md. Background/lock-screen playback and
/// notification controls come for free from `audio_service`/`just_audio`
/// via [PirithAudioHandler]; this screen just reflects [PlayerBloc]'s state.
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          if (state is! PlayerActive) {
            return Center(child: Text(l10n.comingSoon));
          }
          return _NowPlaying(state: state);
        },
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.state});

  final PlayerActive state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isBuffering =
        state.status == PlaybackStatus.loading ||
        state.status == PlaybackStatus.buffering;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PirithArtwork(
            pirithId: state.item.id,
            coverUrl: state.item.coverUrl,
            size: 220,
            radius: 24,
          ),
          const SizedBox(height: 28),
          Text(
            state.item.titleSinhala,
            textAlign: TextAlign.center,
            style: AppTypography.sinhalaTitle(
              fontSize: 22,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(state.item.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Row(
            children: [
              FavoriteButton(pirithId: state.item.id),
              Expanded(
                child: Slider(
                  value: state.position.inMilliseconds
                      .clamp(0, state.duration.inMilliseconds)
                      .toDouble(),
                  max: state.duration.inMilliseconds > 0
                      ? state.duration.inMilliseconds.toDouble()
                      : 1,
                  onChanged: (value) => context.read<PlayerBloc>().add(
                    PlayerSeekRequested(Duration(milliseconds: value.round())),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: l10n.actionDownload,
                onPressed: () => context.read<DownloadBloc>().add(
                  DownloadRequested(state.item),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(state.position),
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  _format(state.duration),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_previous),
                onPressed: null,
                tooltip: l10n.comingSoon,
              ),
              const SizedBox(width: 16),
              isBuffering
                  ? const SizedBox(
                      width: 56,
                      height: 56,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : IconButton.filled(
                      iconSize: 32,
                      icon: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: () => context.read<PlayerBloc>().add(
                        state.isPlaying
                            ? const PlayerPauseRequested()
                            : const PlayerResumeRequested(),
                      ),
                    ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_next),
                onPressed: null,
                tooltip: l10n.comingSoon,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
