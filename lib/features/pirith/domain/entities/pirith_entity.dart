import 'package:equatable/equatable.dart';

import '../../../../core/utils/youtube_url.dart';

/// Domain-level Pirith (chant) entity — see docs/03_database_schema.md.
class PirithEntity extends Equatable {
  const PirithEntity({
    required this.id,
    required this.title,
    required this.titleSinhala,
    required this.description,
    required this.descriptionSinhala,
    required this.coverUrl,
    required this.audioUrl,
    this.youtubeUrl = '',
    this.videoUrl = '',
    required this.duration,
    required this.categoryId,
    required this.isPremium,
    required this.isFeatured,
    required this.sortOrder,
    required this.playCount,
    required this.downloadCount,
  });

  final String id;
  final String title;
  final String titleSinhala;
  final String description;
  final String descriptionSinhala;
  final String coverUrl;
  final String audioUrl;

  /// Optional companion YouTube link, set per-Pirith in the admin app. Empty
  /// when there isn't one, which is the common case.
  final String youtubeUrl;

  /// Optional uploaded companion video, set per-Pirith in the admin app.
  /// Independent of [youtubeUrl] — a Pirith may have either, both, or
  /// neither. Empty when there isn't one.
  final String videoUrl;

  /// Duration in seconds.
  final int duration;
  final String categoryId;
  final bool isPremium;
  final bool isFeatured;
  final int sortOrder;
  final int playCount;
  final int downloadCount;

  /// Whether this Pirith can be played, downloaded or queued.
  ///
  /// The single predicate the audio, download and playlist paths consult.
  /// Deliberately not `!isVideoOnly`: a Pirith with neither audio nor video
  /// must be kept out of those paths too.
  ///
  /// Trimmed here rather than at the call sites because the admin app stores
  /// these URLs as free text, without trimming.
  bool get hasAudio => audioUrl.trim().isNotEmpty;

  /// Whether this Pirith has any video content — an uploaded [videoUrl], a
  /// [youtubeUrl], or both.
  bool get hasVideo => videoUrl.trim().isNotEmpty || youtubeUrl.trim().isNotEmpty;

  /// Video-only: a title, a cover, and an uploaded video or a YouTube link,
  /// but no audio file.
  ///
  /// A presentation predicate — it decides which screen a tap opens. False
  /// when there is no video either, so the video screen can never be opened
  /// on something with nothing to show.
  ///
  /// Derived rather than stored: `PirithModel.fromFirestore` already coerces
  /// a missing `audioUrl` to `''`, so this needs no schema change, no
  /// backfill, and no new cache key — see docs/03_database_schema.md.
  bool get isVideoOnly => !hasAudio && hasVideo;

  /// What [PirithArtwork] should render for this Pirith.
  ///
  /// `coverUrl` wins whenever it's set — an admin who bothered to upload
  /// square artwork gets it everywhere, video or not. Only when there's no
  /// cover AND no audio does a YouTube-derived still stand in, so a
  /// video-only Pirith with no cover reads as "this video" rather than a
  /// generic placeholder. No uploaded-video-only fallback exists (no video
  /// thumbnail is stored anywhere), so that case still falls through to the
  /// id-keyed placeholder in `PirithArtwork`.
  String get displayCoverUrl {
    if (coverUrl.trim().isNotEmpty) return coverUrl;
    if (!isVideoOnly) return coverUrl;
    final videoId = youTubeVideoId(youtubeUrl);
    return videoId == null ? '' : youTubeFallbackThumbnailUrl(videoId);
  }

  String durationLabel() {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        titleSinhala,
        description,
        descriptionSinhala,
        coverUrl,
        audioUrl,
        youtubeUrl,
        videoUrl,
        duration,
        categoryId,
        isPremium,
        isFeatured,
        sortOrder,
        playCount,
        downloadCount,
      ];
}
