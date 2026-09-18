import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/external_link_launcher.dart';
import '../../../../core/utils/youtube_url.dart';

/// YouTube's brand red, for the play badge.
const _youTubeRed = Color(0xFFFF0000);

/// Preview of a Pirith's companion video: the video's own thumbnail with a
/// play badge, opening YouTube when tapped.
///
/// This deliberately does not reuse [PirithArtwork], despite that being the
/// app's network-image-with-fallback pattern and [PlaylistCover] setting a
/// reuse precedent. That widget takes fixed pixel dimensions where this needs
/// to fill the content width, and its placeholder is the dhamma-wheel mark on
/// an id-keyed gradient — the right signal for chant artwork and the wrong one
/// for a video. The *pattern* is reused; the widget is not.
///
/// The label and badge are intentionally theme-independent, unlike the rest of
/// the player: they sit on a photograph. Everything not on the photograph —
/// the placeholder fill, the border, the ink — comes from the theme.
class YouTubePreviewCard extends StatelessWidget {
  const YouTubePreviewCard({required this.youtubeUrl, super.key});

  final String youtubeUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final videoId = youTubeVideoId(youtubeUrl);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        // Clipped so a long label can never overflow the card's rounded edge.
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Always painted, so a slow, failed or unresolvable thumbnail
              // leaves a card rather than a hole.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              if (videoId != null) _Thumbnail(videoId: videoId),
              // Keeps the label legible over any thumbnail.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              const Center(child: _PlayBadge()),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.actionWatchOnYouTube,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    // Captured before the await — reading them from `context` afterwards is
    // the across-async-gap trap, and the pattern used elsewhere in the app.
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).linkErrorGeneric;

    // Launch a normalised URL when the link parsed: a stored "youtu.be/ID"
    // with no scheme resolves fine here but fails in launchUrl, which the
    // user sees as a dead tap.
    final videoId = youTubeVideoId(youtubeUrl);
    final target = videoId == null
        ? youtubeUrl.trim()
        : youTubeWatchUrl(videoId);

    // launchExternalUrl returns whether it worked and every other call site
    // in the app ignores it. Worth surfacing here: this link is unvalidated
    // admin free text, and a silent no-op on a card this large reads as a
    // broken app.
    if (await launchExternalUrl(target)) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The video still, falling back one step in quality before giving up.
class _Thumbnail extends StatefulWidget {
  const _Thumbnail({required this.videoId});

  final String videoId;

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  /// `maxresdefault` is 1280x720 but simply doesn't exist for a lot of
  /// videos, so a 404 here is an ordinary outcome rather than an error —
  /// hence the retry at a size YouTube always publishes.
  bool _useFallback = false;

  @override
  void didUpdateWidget(_Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) _useFallback = false;
  }

  @override
  Widget build(BuildContext context) {
    final url = _useFallback
        ? youTubeFallbackThumbnailUrl(widget.videoId)
        : youTubeThumbnailUrl(widget.videoId);

    return Image.network(
      url,
      key: ValueKey(url),
      // cover, not contain: the fallback still is 4:3 with letterbox bars,
      // and cropping is exactly how those bars come back off.
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) {
        if (!_useFallback) {
          // Can't setState during build; schedule it for the next frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _useFallback = true);
          });
        }
        // Either retrying or out of options — show the card's own base layer.
        return const SizedBox.shrink();
      },
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SizedBox.shrink(),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        color: _youTubeRed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
    );
  }
}
