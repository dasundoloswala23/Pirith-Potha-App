import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/external_link_launcher.dart';
import '../../../downloads/domain/entities/download_entity.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../domain/entities/playback_status.dart';
import '../bloc/player_bloc.dart';
import '../bloc/sleep_timer_cubit.dart';

/// Full-screen "now playing", driven by the app-scoped [PlayerBloc] — see
/// docs/04_audio_architecture.md. Background/lock-screen playback and
/// notification controls come for free from `audio_service`/`just_audio`
/// via [PirithAudioHandler]; this screen just reflects [PlayerBloc]'s state.
///
/// Follows the app's light/dark theme rather than forcing its own palette,
/// so the listening screen matches the rest of the app.
class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          l10n.nowPlaying.toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
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

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 16:9 rather than square, so wide cover art isn't cropped. Width
          // is capped so the resulting height can't crowd out the controls
          // on a short screen.
          final coverWidth = constraints.maxWidth.clamp(
            200.0,
            constraints.maxHeight * 0.45 * 16 / 9,
          );
          final coverHeight = coverWidth * 9 / 16;
          // No Spacer/Expanded here: this Column lives inside a scroll
          // view, so its height is unbounded and a flex child would have
          // nothing to expand into — it silently collapses the whole body.
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  _Artwork(
                    state: state,
                    width: coverWidth,
                    height: coverHeight,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _TitleBlock(state: state),
                  const SizedBox(height: AppSpacing.lg),
                  _ActionRow(item: state.item),
                  const SizedBox(height: AppSpacing.lg),
                  _Progress(state: state),
                  const SizedBox(height: AppSpacing.md),
                  _Transport(state: state, isBuffering: isBuffering),
                  const SizedBox(height: AppSpacing.md),
                  const _SleepTimerButton(),
                  // Kept well below the transport row: an ad crowding the
                  // play controls invites accidental taps, which AdMob
                  // counts as invalid traffic.
                  const SizedBox(height: AppSpacing.xl),
                  const BannerAdWidget(mediumRectangle: true),
                  if (state.item.youtubeUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => launchExternalUrl(state.item.youtubeUrl),
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Color(0xFFFF0000),
                      ),
                      label: Text(
                        l10n.actionWatchOnYouTube,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Cover art over a soft glow, so the artwork reads as lit rather than
/// pasted onto a flat dark panel.
class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.state,
    required this.width,
    required this.height,
  });

  final PlayerActive state;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        size: width,
        height: height,
        radius: 20,
      ),
    );
  }
}

/// Title block: the Sinhala name carries the hierarchy, with the English
/// name and duration deliberately quieter beneath it.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.state});

  final PlayerActive state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          state.item.titleSinhala,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sinhalaTitle(
            fontSize: 24,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (state.item.title.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.item.title,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.englishSerif(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Favourite and download as labelled secondary actions — deliberately
/// quiet text buttons so neither competes with the play control.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.item});

  final PirithEntity item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final isFavorite = context.select<FavoritesBloc, bool>((bloc) {
      final state = bloc.state;
      return state is FavoritesLoaded && state.ids.contains(item.id);
    });

    final entry = context.select<DownloadBloc, DownloadEntity?>((bloc) {
      final state = bloc.state;
      return state is DownloadsLoaded ? state.statusFor(item.id) : null;
    });

    final (
      downloadIcon,
      downloadLabel,
      downloadEnabled,
    ) = switch (entry?.status) {
      DownloadStatus.downloading => (
        Icons.downloading,
        l10n.downloadInProgress,
        false,
      ),
      DownloadStatus.downloaded => (
        Icons.download_done,
        l10n.downloadedLabel,
        false,
      ),
      DownloadStatus.failed => (Icons.error_outline, l10n.actionRetry, true),
      _ => (Icons.download_outlined, l10n.actionDownload, true),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () =>
              context.read<FavoritesBloc>().add(FavoriteToggled(item.id)),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite
                ? AppColors.maroonDark
                : theme.colorScheme.primary,
            size: 20,
          ),
          label: Text(
            isFavorite ? l10n.actionFavorite : l10n.actionAddFavorite,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: downloadEnabled
              ? () => context.read<DownloadBloc>().add(DownloadRequested(item))
              : null,
          icon: Icon(
            downloadIcon,
            size: 20,
            color: entry?.status == DownloadStatus.downloaded
                ? AppColors.green
                : theme.colorScheme.primary,
          ),
          label: Text(
            downloadLabel,
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

/// Sleep timer entry point. Shows the remaining minutes once armed, so the
/// state is visible without opening the sheet.
class _SleepTimerButton extends StatelessWidget {
  const _SleepTimerButton();

  static const _options = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = context.watch<SleepTimerCubit>().state;

    return TextButton.icon(
      onPressed: () => _openSheet(context, minutes),
      icon: Icon(
        minutes == null ? Icons.bedtime_outlined : Icons.bedtime,
        size: 20,
        color: minutes == null ? theme.colorScheme.primary : AppColors.goldDark,
      ),
      label: Text(
        minutes == null ? l10n.sleepTimerTitle : l10n.sleepTimerActive(minutes),
        style: TextStyle(
          color: minutes == null
              ? theme.colorScheme.primary
              : AppColors.goldDark,
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, int? current) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<SleepTimerCubit>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.sleepTimerTitle,
                style: AppTypography.sinhalaTitle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            for (final option in [null, ..._options])
              ListTile(
                title: Text(
                  option == null
                      ? l10n.sleepTimerOff
                      : l10n.sleepTimerMinutes(option),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                trailing: option == current
                    ? const Icon(Icons.check, color: AppColors.goldDark)
                    : null,
                onTap: () {
                  cubit.setMinutes(option);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final PlayerActive state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.duration.inMilliseconds;
    final position = state.position.inMilliseconds.clamp(0, total).toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: AppColors.goldDark,
            inactiveTrackColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.25,
            ),
            thumbColor: AppColors.goldDark,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            trackShape: const RoundedRectSliderTrackShape(),
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
              Text(_clock(state.position), style: theme.textTheme.labelSmall),
              Text(_clock(state.duration), style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }

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
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip back/forward rather than previous/next track: there are no
        // playlists yet, and on a 12-to-60-minute chant nudging the position
        // is the thing people actually reach for.
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10),
          color: theme.colorScheme.onSurface,
          tooltip: l10n.actionRewind10,
          onPressed: () =>
              _seekBy(context, state, const Duration(seconds: -10)),
        ),
        const SizedBox(width: AppSpacing.xl),
        _PlayPauseButton(state: state, isBuffering: isBuffering),
        const SizedBox(width: AppSpacing.xl),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_10),
          color: theme.colorScheme.onSurface,
          tooltip: l10n.actionForward10,
          onPressed: () => _seekBy(context, state, const Duration(seconds: 10)),
        ),
      ],
    );
  }
}

/// Nudges playback, clamped so a skip near either end can't seek out of
/// bounds.
void _seekBy(BuildContext context, PlayerActive state, Duration delta) {
  final target = state.position + delta;
  final clamped = target < Duration.zero
      ? Duration.zero
      : (target > state.duration ? state.duration : target);
  context.read<PlayerBloc>().add(PlayerSeekRequested(clamped));
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
