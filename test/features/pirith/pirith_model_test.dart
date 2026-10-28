import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/data/models/pirith_model.dart';

Map<String, dynamic> _json({Object? categoryId = 'protective'}) => {
  'id': '1',
  'title': 'Ratana Sutta',
  'titleSinhala': 'රතන සූත්‍රය',
  'description': '',
  'descriptionSinhala': '',
  'coverUrl': '',
  'audioUrl': 'https://example.com/a.mp3',
  'duration': 0,
  'categoryId': categoryId,
  'isPremium': false,
  'isFeatured': false,
  'sortOrder': 1,
  'playCount': 0,
  'downloadCount': 0,
};

void main() {
  group('PirithModel.fromJson categoryId', () {
    test('present — decodes as-is', () {
      expect(
        PirithModel.fromJson(_json(categoryId: 'protective')).categoryId,
        'protective',
      );
    });

    test('null — a Pirith can genuinely have no category', () {
      expect(PirithModel.fromJson(_json(categoryId: null)).categoryId, '');
    });

    test('absent — entries cached before the admin allowed no category', () {
      final json = _json()..remove('categoryId');
      expect(PirithModel.fromJson(json).categoryId, '');
    });
  });
}
