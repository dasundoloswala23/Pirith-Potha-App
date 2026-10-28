import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';

PirithEntity _pirith({
  String audioUrl = '',
  String youtubeUrl = '',
  String videoUrl = '',
  String coverUrl = '',
}) {
  return PirithEntity(
    id: '1',
    title: 'Ratana Sutta',
    titleSinhala: 'රතන සූත්‍රය',
    description: '',
    descriptionSinhala: '',
    coverUrl: coverUrl,
    audioUrl: audioUrl,
    youtubeUrl: youtubeUrl,
    videoUrl: videoUrl,
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
  const upload = 'https://example.com/v.mp4';

  group('hasAudio / isVideoOnly', () {
    test('audio only', () {
      final item = _pirith(audioUrl: audio);
      expect(item.hasAudio, isTrue);
      expect(item.isVideoOnly, isFalse);
    });

    test('audio + uploaded video — audio wins, not video-only', () {
      final item = _pirith(audioUrl: audio, videoUrl: upload);
      expect(item.hasAudio, isTrue);
      expect(item.isVideoOnly, isFalse);
    });

    test('video only (YouTube)', () {
      final item = _pirith(youtubeUrl: video);
      expect(item.hasAudio, isFalse);
      expect(item.isVideoOnly, isTrue);
    });

    test('video only (uploaded)', () {
      final item = _pirith(videoUrl: upload);
      expect(item.hasAudio, isFalse);
      expect(item.isVideoOnly, isTrue);
    });

    test('both — audio wins, so it is not video-only', () {
      final item = _pirith(audioUrl: audio, youtubeUrl: video);
      expect(item.hasAudio, isTrue);
      expect(item.isVideoOnly, isFalse);
    });

    test('no audio + both video sources — still video-only', () {
      final item = _pirith(videoUrl: upload, youtubeUrl: video);
      expect(item.hasAudio, isFalse);
      expect(item.isVideoOnly, isTrue);
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
      expect(_pirith(videoUrl: '  ').isVideoOnly, isFalse);
      expect(_pirith(audioUrl: '  ', youtubeUrl: video).isVideoOnly, isTrue);
      expect(_pirith(audioUrl: '  ', videoUrl: upload).isVideoOnly, isTrue);
    });
  });

  group('displayCoverUrl', () {
    const cover = 'https://example.com/cover.jpg';

    test('cover set — wins regardless of audio/video', () {
      expect(_pirith(coverUrl: cover, audioUrl: audio).displayCoverUrl, cover);
      expect(_pirith(coverUrl: cover, videoUrl: upload).displayCoverUrl, cover);
      expect(_pirith(coverUrl: cover).displayCoverUrl, cover);
    });

    test('no cover, audio-only — stays empty, no YouTube fallback', () {
      expect(_pirith(audioUrl: audio).displayCoverUrl, '');
    });

    test(
      'no cover, video-only with a resolvable YouTube id — uses the still',
      () {
        final item = _pirith(youtubeUrl: video);
        expect(item.displayCoverUrl, contains('dQw4w9WgXcQ'));
        expect(item.displayCoverUrl, contains('hqdefault.jpg'));
      },
    );

    test('no cover, video-only with an unparseable YouTube link — empty', () {
      final item = _pirith(youtubeUrl: 'not a youtube link');
      expect(item.displayCoverUrl, '');
    });

    test('no cover, uploaded-video-only with no YouTube link — empty', () {
      final item = _pirith(videoUrl: upload);
      expect(item.displayCoverUrl, '');
    });

    test('no cover, neither audio nor video — empty', () {
      expect(_pirith().displayCoverUrl, '');
    });
  });
}
