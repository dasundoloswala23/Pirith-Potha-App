import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/ads/widgets/banner_ad_widget.dart';
import '../../../../core/constants/app_route_paths.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/bilingual.dart';
import '../../../downloads/domain/entities/download_entity.dart';
import '../../../downloads/presentation/bloc/download_bloc.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';
import '../../../pirith/domain/entities/pirith_entity.dart';
import '../../../pirith/presentation/widgets/pirith_artwork.dart';
import '../../../playlists/presentation/widgets/add_to_playlist_sheet.dart';
import '../../domain/entities/playback_mode.dart';
import '../../domain/entities/playback_status.dart';
import '../bloc/player_bloc.dart';
import '../bloc/sleep_timer_cubit.dart';
import '../widgets/player_artwork.dart';
import '../widgets/player_title_block.dart';
import '../widgets/youtube_preview_card.dart';

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
                  PlayerArtwork(
                    item: state.item,
                    width: coverWidth,
                    height: coverHeight,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PlayerTitleBlock(item: state.item),
                  const SizedBox(height: AppSpacing.lg),
                  _ActionRow(item: state.item),
                  const SizedBox(height: AppSpacing.lg),
                  _Progress(state: state),
                  const SizedBox(height: AppSpacing.md),
                  _Transport(state: state, isBuffering: isBuffering),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _PlaybackModeButton(mode: state.mode),
                      const _SleepTimerButton(),
                      // Long-press is the only other way to reach this, and
                      // it advertises nothing; the player has the room for a
                      // labelled control.
                      _PlayerChip(
                        icon: Icons.playlist_add,
                        label: Bilingual.of(context).primary.playlistAddTo,
                        active: false,
                        onTap: () => showAddToPlaylistSheet(
                          context,
                          pirithId: state.item.id,
                          pirithTitle: state.item.titleSinhala,
                        ),
                      ),
                      if (state.queue.length > 1)
                        _PlayerChip(
                          icon: Icons.queue_music,
                          label: Bilingual.of(context).primary.queueTitle,
                          active: false,
                          onTap: () => context.push(AppRoutePaths.queue),
                        ),
                    ],
                  ),
                  // The button this replaced brought its own padding, so the
                  // Wrap above needed no spacer; a card butted against the
                  // chips would read as a layout bug.
                  if (state.item.youtubeUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    YouTubePreviewCard(youtubeUrl: state.item.youtubeUrl),
                  ],
                  // Last thing on the screen, well clear of the transport
                  // row: an ad crowding the play controls invites accidental
                  // taps, which AdMob counts as invalid traffic.
                  const SizedBox(height: AppSpacing.xl),
                  const BannerAdWidget(mediumRectangle: true),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
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

/// Pill used by the secondary player controls. Filled when the setting is
/// active and outlined when it isn't, so "on" is legible at a glance
/// rather than depending on the icon alone.
class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final idle = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final foreground = active ? accent : idle;

    return Material(
      color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.5)
                  : idle.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycles through the playback modes, naming the one that is active so
/// the icon alone never has to carry the meaning.
class _PlaybackModeButton extends StatelessWidget {
  const _PlaybackModeButton({required this.mode});

  final PlaybackMode mode;

  @override
  Widget build(BuildContext context) {
    // Sinhala leads here as everywhere else: these chips sit in one row
    // and a mix of Sinhala and English labels reads as a mistake.
    final l10n = Bilingual.of(context).primary;
    final isDefault = mode == PlaybackMode.normal;

    final (icon, label) = switch (mode) {
      PlaybackMode.normal => (Icons.trending_flat, l10n.modeNormal),
      PlaybackMode.repeatAll => (Icons.repeat, l10n.modeRepeatAll),
      PlaybackMode.repeatOne => (Icons.repeat_one, l10n.modeRepeatOne),
      PlaybackMode.shuffle => (Icons.shuffle, l10n.modeShuffle),
    };

    return _PlayerChip(
      icon: icon,
      label: label,
      active: !isDefault,
      onTap: () => context.read<PlayerBloc>().add(PlayerModeChanged(mode.next)),
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
    final l10n = Bilingual.of(context).primary;
    final minutes = context.watch<SleepTimerCubit>().state;

    return _PlayerChip(
      icon: minutes == null ? Icons.bedtime_outlined : Icons.bedtime,
      label: minutes == null
          ? l10n.sleepTimerTitle
          : l10n.sleepTimerActive(minutes),
      active: minutes != null,
      onTap: () => _openSheet(context, minutes),
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

    // ±10s always stays: on a 12-to-60-minute chant, nudging the position is
    // what people actually reach for. Previous/next join it only when there
    // is a queue to move through, so a single Pirith keeps the roomier
    // three-button layout.
    final hasSkips = state.hasPrevious || state.hasNext;
    final gap = hasSkips ? AppSpacing.md : AppSpacing.xl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasSkips) ...[
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.skip_previous),
            color: theme.colorScheme.onSurface,
            tooltip: l10n.actionPrevious,
            onPressed: state.hasPrevious
                ? () =>
                      context.read<PlayerBloc>().add(
                        const PlayerPreviousRequested(),
                      )
                : null,
          ),
          SizedBox(width: gap),
        ],
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10),
          color: theme.colorScheme.onSurface,
          tooltip: l10n.actionRewind10,
          onPressed: () =>
              _seekBy(context, state, const Duration(seconds: -10)),
        ),
        SizedBox(width: gap),
        _PlayPauseButton(state: state, isBuffering: isBuffering),
        SizedBox(width: gap),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_10),
          color: theme.colorScheme.onSurface,
          tooltip: l10n.actionForward10,
          onPressed: () => _seekBy(context, state, const Duration(seconds: 10)),
        ),
        if (hasSkips) ...[
          SizedBox(width: gap),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.skip_next),
            color: theme.colorScheme.onSurface,
            tooltip: l10n.actionNext,
            onPressed: state.hasNext
                ? () =>
                      context.read<PlayerBloc>().add(
                        const PlayerNextRequested(),
                      )
                : null,
          ),
        ],
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
