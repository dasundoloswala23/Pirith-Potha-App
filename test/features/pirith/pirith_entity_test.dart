import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';

PirithEntity _pirith({String audioUrl = '', String youtubeUrl = ''}) {
  return PirithEntity(
    id: '1',
    title: 'Ratana Sutta',
    titleSinhala: 'රතන සූත්‍රය',
    description: '',
    descriptionSinhala: '',
    coverUrl: '',
    audioUrl: audioUrl,
    youtubeUrl: youtubeUrl,
    duration: 0,
    categoryId: 'protective',
    isPremium: false,
    isFeatured: false,
    sortOrder: 1,
    playCount: 0,
    downloadCount: 0,
  );
}

void main() {
  const audio = 'https://example.com/a.mp3';
  const video = 'https://youtu.be/dQw4w9WgXcQ';

  group('hasAudio / isVideoOnly', () {
    test('audio only', () {
      final item = _pirith(audioUrl: audio);
      expect(item.hasAudio, isTrue);
      expect(item.isVideoOnly, isFalse);
    });

    test('video only', () {
      final item = _pirith(youtubeUrl: video);
      expect(item.hasAudio, isFalse);
      expect(item.isVideoOnly, isTrue);
    });

    test('both — audio wins, so it is not video-only', () {
      final item = _pirith(audioUrl: audio, youtubeUrl: video);
      expect(item.hasAudio, isTrue);
      expect(item.isVideoOnly, isFalse);
    });

    test('neither — not playable and not video-only', () {
      // The screen must refuse to open on this, rather than showing an
      // empty video card.
      final item = _pirith();
      expect(item.hasAudio, isFalse);
      expect(item.isVideoOnly, isFalse);
    });

    test('whitespace-only urls do not count', () {
      // The admin app stores these fields untrimmed.
      expect(_pirith(audioUrl: '   ').hasAudio, isFalse);
      expect(_pirith(youtubeUrl: '  ').isVideoOnly, isFalse);
      expect(_pirith(audioUrl: '  ', youtubeUrl: video).isVideoOnly, isTrue);
    });
  });
}
