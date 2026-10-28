import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../bloc/player_bloc.dart';
import 'youtube_preview_card.dart';

/// The Pirith video area: an uploaded video, a YouTube preview, both, or
/// neither — self-contained, like [YouTubePreviewCard] already is, so every
/// caller places it unconditionally with no surrounding `if`.
///
/// Display order when both exist: uploaded video first, YouTube preview
/// underneath. Either alone renders just that half. Neither renders nothing,
/// with no leftover spacing, so a Pirith with no video content looks
/// identical to this widget not being there at all.
class VideoSection extends StatelessWidget {
  const VideoSection({
    required this.videoUrl,
    required this.youtubeUrl,
    super.key,
  });

  final String videoUrl;
  final String youtubeUrl;

  @override
  Widget build(BuildContext context) {
    final hasVideo = videoUrl.trim().isNotEmpty;
    final hasYoutube = youtubeUrl.trim().isNotEmpty;

    if (!hasVideo && !hasYoutube) return const SizedBox.shrink();

    return Column(
      children: [
        if (hasVideo) _UploadedVideoPlayer(url: videoUrl),
        if (hasVideo && hasYoutube) const SizedBox(height: AppSpacing.md),
        if (hasYoutube) YouTubePreviewCard(youtubeUrl: youtubeUrl),
      ],
    );
  }
}

/// Real in-app playback for an uploaded video file, via `video_player` +
/// `chewie`. Owns its controllers for its own lifetime only — never promoted
/// to a shared instance, since video has no background, lock-screen or
/// queue requirement (see docs/04_audio_architecture.md).
class _UploadedVideoPlayer extends StatefulWidget {
  const _UploadedVideoPlayer({required this.url});

  final String url;

  @override
  State<_UploadedVideoPlayer> createState() => _UploadedVideoPlayerState();
}

class _UploadedVideoPlayerState extends State<_UploadedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  bool _failed = false;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _init(widget.url);
  }

  @override
  void didUpdateWidget(_UploadedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeControllers();
      setState(() {
        _loading = true;
        _failed = false;
      });
      _init(widget.url);
    }
  }

  Future<void> _init(String url) async {
    final videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await videoController.initialize();
    } catch (_) {
      videoController.dispose();
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      videoController.dispose();
      return;
    }
    videoController.addListener(_onVideoValueChanged);
    final chewieController = ChewieController(
      videoPlayerController: videoController,
      aspectRatio: 16 / 9,
      autoInitialize: false,
      autoPlay: false,
      looping: false,
      showControlsOnInitialize: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.gold,
        handleColor: AppColors.gold,
        bufferedColor: AppColors.lightBorder,
        backgroundColor: Colors.white24,
      ),
    );
    setState(() {
      _videoController = videoController;
      _chewieController = chewieController;
      _loading = false;
    });
  }

  void _onVideoValueChanged() {
    final isPlaying = _videoController?.value.isPlaying ?? false;
    if (isPlaying && !_wasPlaying) {
      context.read<PlayerBloc>().add(const PlayerPauseRequested());
    }
    _wasPlaying = isPlaying;
  }

  void _disposeControllers() {
    _videoController?.removeListener(_onVideoValueChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Pauses the uploaded video when audio starts elsewhere — the reverse of
  /// [_onVideoValueChanged]'s audio-pausing-on-video-play, so the two never
  /// play at once regardless of which started first. Only the video widget
  /// needs to know about this; [PlayerBloc] doesn't know video exists.
  void _onPlayerStateChanged(BuildContext context, PlayerState state) {
    if (state is! PlayerActive || !state.isPlaying) return;
    final controller = _videoController;
    if (controller != null && controller.value.isPlaying) controller.pause();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget filled(Widget child) => BlocListener<PlayerBloc, PlayerState>(
      listener: _onPlayerStateChanged,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (_failed) {
      return filled(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context).videoUnavailable,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_loading || _chewieController == null) {
      return filled(
        const Center(
          child: CircularProgressIndicator(color: AppColors.goldDark),
        ),
      );
    }

    return filled(Chewie(controller: _chewieController!));
  }
}
