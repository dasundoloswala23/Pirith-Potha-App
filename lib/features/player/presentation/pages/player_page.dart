import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/external_link_launcher.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../domain/entities/playback_status.dart';
import '../bloc/player_bloc.dart';

/// Full-screen "now playing", driven by the app-scoped [PlayerBloc] — see
/// docs/04_audio_architecture.md. Background/lock-screen playback and
/// notification controls come for free from `audio_service`/`just_audio`
/// via [PirithAudioHandler]; this screen just reflects [PlayerBloc]'s state.
///
/// Always dark regardless of the app theme, per the approved design: the
/// listening screen is meant to recede, and [AppColors] already carries a
/// dedicated player palette for exactly this.
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Theme(
      data: AppTheme.dark.copyWith(
        scaffoldBackgroundColor: AppColors.player,
        colorScheme: AppTheme.dark.colorScheme.copyWith(
          surface: AppColors.player,
          onSurface: AppColors.playerText,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.playerText),
          title: Text(
            l10n.nowPlaying.toUpperCase(),
            style: const TextStyle(
              color: AppColors.playerTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        body: BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, state) {
            if (state is! PlayerActive) {
              return Center(
                child: Text(
                  l10n.comingSoon,
                  style: const TextStyle(color: AppColors.playerText),
                ),
              );
            }
            return _NowPlaying(state: state);
          },
        ),
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
    final isBuffering =
        state.status == PlaybackStatus.loading ||
        state.status == PlaybackStatus.buffering;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              _Artwork(state: state),
              const SizedBox(height: AppSpacing.xxl),
              _TitleRow(state: state),
              const SizedBox(height: AppSpacing.lg),
              _Progress(state: state),
              const SizedBox(height: AppSpacing.lg),
              _Transport(state: state, isBuffering: isBuffering),
              if (state.item.youtubeUrl.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                TextButton.icon(
                  onPressed: () => launchExternalUrl(state.item.youtubeUrl),
                  icon: const Icon(
                    Icons.play_circle_fill,
                    color: Color(0xFFFF0000),
                  ),
                  label: Text(
                    l10n.actionWatchOnYouTube,
                    style: const TextStyle(
                      color: AppColors.playerTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cover art over a soft glow, so the artwork reads as lit rather than
/// pasted onto a flat dark panel.
class _Artwork extends StatelessWidget {
  const _Artwork({required this.state});

  final PlayerActive state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: PirithArtwork(
        pirithId: state.item.id,
        coverUrl: state.item.coverUrl,
        size: 250,
        radius: 28,
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.state});

  final PlayerActive state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.item.titleSinhala,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.sinhalaTitle(
                  fontSize: 20,
                  color: AppColors.playerText,
                ),
              ),
              if (state.item.title.isNotEmpty)
                Text(
                  state.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.englishSerif(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.playerTextSecondary,
                  ),
                ),
            ],
          ),
        ),
        FavoriteButton(pirithId: state.item.id),
        IconButton(
          icon: const Icon(Icons.download_outlined),
          color: AppColors.playerTextSecondary,
          tooltip: AppLocalizations.of(context).actionDownload,
          onPressed: () =>
              context.read<DownloadBloc>().add(DownloadRequested(state.item)),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final PlayerActive state;

  @override
  Widget build(BuildContext context) {
    final total = state.duration.inMilliseconds;
    final position = state.position.inMilliseconds.clamp(0, total).toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: AppColors.goldDark,
            inactiveTrackColor: AppColors.playerTextSecondary.withValues(
              alpha: 0.25,
            ),
            thumbColor: AppColors.goldDark,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: position,
            max: total > 0 ? total.toDouble() : 1,
            onChanged: (value) => context.read<PlayerBloc>().add(
              PlayerSeekRequested(Duration(milliseconds: value.round())),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_clock(state.position), style: _timeStyle),
              Text(_clock(state.duration), style: _timeStyle),
            ],
          ),
        ),
      ],
    );
  }

  static const _timeStyle = TextStyle(
    color: AppColors.playerTextSecondary,
    fontSize: 12,
  );

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _Transport extends StatelessWidget {
  const _Transport({required this.state, required this.isBuffering});

  final PlayerActive state;
  final bool isBuffering;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous/next stay disabled until playlists exist (V1.1) — shown
        // rather than hidden so the transport keeps the shape people expect.
        IconButton(
          iconSize: 30,
          icon: const Icon(Icons.skip_previous),
          color: AppColors.playerTextSecondary.withValues(alpha: 0.4),
          tooltip: l10n.comingSoon,
          onPressed: null,
        ),
        const SizedBox(width: AppSpacing.xl),
        _PlayPauseButton(state: state, isBuffering: isBuffering),
        const SizedBox(width: AppSpacing.xl),
        IconButton(
          iconSize: 30,
          icon: const Icon(Icons.skip_next),
          color: AppColors.playerTextSecondary.withValues(alpha: 0.4),
          tooltip: l10n.comingSoon,
          onPressed: null,
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.state, required this.isBuffering});

  final PlayerActive state;
  final bool isBuffering;

  @override
  Widget build(BuildContext context) {
    if (isBuffering) {
      return const SizedBox(
        width: 72,
        height: 72,
        child: Padding(
          padding: EdgeInsets.all(18),
          child: CircularProgressIndicator(color: AppColors.goldDark),
        ),
      );
    }

    return Material(
      color: AppColors.goldDark,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.read<PlayerBloc>().add(
          state.isPlaying
              ? const PlayerPauseRequested()
              : const PlayerResumeRequested(),
        ),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(
            state.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}
