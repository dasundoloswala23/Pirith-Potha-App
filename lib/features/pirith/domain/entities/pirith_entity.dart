import 'package:equatable/equatable.dart';

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

  /// Optional companion video, set per-Pirith in the admin app. Empty when
  /// there isn't one, which is the common case.
  final String youtubeUrl;

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

  /// Video-only: a title, a cover and a YouTube link, but no audio file.
  ///
  /// A presentation predicate — it decides which screen a tap opens. False
  /// when there is no video either, so the video screen can never be opened
  /// on something with nothing to show.
  ///
  /// Derived rather than stored: `PirithModel.fromFirestore` already coerces
  /// a missing `audioUrl` to `''`, so this needs no schema change, no
  /// backfill, and no new cache key — see docs/03_database_schema.md.
  bool get isVideoOnly => !hasAudio && youtubeUrl.trim().isNotEmpty;

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
        duration,
        categoryId,
        isPremium,
        isFeatured,
        sortOrder,
        playCount,
        downloadCount,
      ];
}
