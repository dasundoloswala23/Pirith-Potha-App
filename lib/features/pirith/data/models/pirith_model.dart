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

  factory PirithModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return PirithModel(
      id: doc.id,
      title: (data['titleEnglish'] as String?) ?? '',
      titleSinhala: (data['titleSinhala'] as String?) ?? '',
      description: (data['descriptionEnglish'] as String?) ?? '',
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

  /// Local on-disk cache (see PirithLocalDataSource), so the app can keep
  /// showing the catalogue — and downloaded Pirith stay properly titled —
  /// with no network at all. Keys here are this class's own field names,
  /// deliberately independent of the Firestore document keys read above
  /// (`titleEnglish`/`descriptionEnglish`), so a schema rename on the
  /// Firestore side can't invalidate every existing install's cache.
  factory PirithModel.fromJson(Map<String, dynamic> json) {
    return PirithModel(
      id: json['id'] as String,
      title: json['title'] as String,
      titleSinhala: json['titleSinhala'] as String,
      description: json['description'] as String,
      descriptionSinhala: json['descriptionSinhala'] as String,
      coverUrl: json['coverUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      duration: json['duration'] as int,
      categoryId: json['categoryId'] as String,
      isPremium: json['isPremium'] as bool,
      isFeatured: json['isFeatured'] as bool,
      sortOrder: json['sortOrder'] as int,
      playCount: json['playCount'] as int,
      downloadCount: json['downloadCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'titleSinhala': titleSinhala,
    'description': description,
    'descriptionSinhala': descriptionSinhala,
    'coverUrl': coverUrl,
    'audioUrl': audioUrl,
    'duration': duration,
    'categoryId': categoryId,
    'isPremium': isPremium,
    'isFeatured': isFeatured,
    'sortOrder': sortOrder,
    'playCount': playCount,
    'downloadCount': downloadCount,
  };
}
