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
