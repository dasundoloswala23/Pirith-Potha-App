import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.nameSinhala,
    required super.sortOrder,
  });

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return CategoryModel(
      id: doc.id,
      name: (data['nameEnglish'] as String?) ?? '',
      nameSinhala: (data['nameSinhala'] as String?) ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// See PirithModel.fromJson — same local-cache purpose.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameSinhala: json['nameSinhala'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameSinhala': nameSinhala,
    'sortOrder': sortOrder,
  };
}
