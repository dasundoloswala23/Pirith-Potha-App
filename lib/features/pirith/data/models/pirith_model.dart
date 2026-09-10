import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pirith_entity.dart';

class PirithModel extends PirithEntity {
  const PirithModel({
    required super.id,
    required super.title,
    required super.titleSinhala,
    required super.description,
    required super.descriptionSinhala,
    required super.coverUrl,
    required super.audioUrl,
    required super.duration,
    required super.categoryId,
    required super.isPremium,
    required super.isFeatured,
    required super.sortOrder,
    required super.playCount,
    required super.downloadCount,
  });

  factory PirithModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return PirithModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      titleSinhala: (data['titleSinhala'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      descriptionSinhala: (data['descriptionSinhala'] as String?) ?? '',
      coverUrl: (data['coverUrl'] as String?) ?? '',
      audioUrl: (data['audioUrl'] as String?) ?? '',
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      categoryId: (data['categoryId'] as String?) ?? '',
      isPremium: (data['isPremium'] as bool?) ?? false,
      isFeatured: (data['isFeatured'] as bool?) ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      playCount: (data['playCount'] as num?)?.toInt() ?? 0,
      downloadCount: (data['downloadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
