import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/features/pirith/domain/entities/pirith_entity.dart';
import 'package:pitithpotha/features/player/domain/playable_queue.dart';

PirithEntity _pirith(String id, {String audioUrl = '', String youtubeUrl = ''}) {
  return PirithEntity(
    id: id,
    title: 'Sutta $id',
    titleSinhala: 'සූත්‍රය $id',
    description: '',
    descriptionSinhala: '',
    coverUrl: '',
    audioUrl: audioUrl,
    youtubeUrl: youtubeUrl,
    duration: 100,
    categoryId: 'protective',
    isPremium: false,
    isFeatured: false,
    sortOrder: 1,
    playCount: 0,
    downloadCount: 0,
  );
}

PirithEntity _audio(String id) => _pirith(id, audioUrl: 'https://x/$id.mp3');
PirithEntity _video(String id) =>
    _pirith(id, youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ');

void main() {
  group('playableQueue', () {
    test('an empty queue stays empty', () {
      final result = playableQueue(const []);
      expect(result.items, isEmpty);
      expect(result.index, 0);
    });

    test('leaves an all-playable queue untouched', () {
      final items = [_audio('a'), _audio('b'), _audio('c')];
      final result = playableQueue(items, startIndex: 2);
      expect(result.items.map((i) => i.id), ['a', 'b', 'c']);
      expect(result.index, 2);
    });

    test('a video before the target pulls the index back', () {
      final items = [_video('v'), _audio('a'), _audio('b')];
      final result = playableQueue(items, startIndex: 1);
      expect(result.items.map((i) => i.id), ['a', 'b']);
      // 'a' was at 1 in the original list and is at 0 in the filtered one.
      expect(result.index, 0);
    });

    test('a video after the target leaves the index alone', () {
      final items = [_audio('a'), _audio('b'), _video('v')];
      final result = playableQueue(items, startIndex: 0);
      expect(result.items.map((i) => i.id), ['a', 'b']);
      expect(result.index, 0);
    });

    test('starting on a video falls back to the first playable item', () {
      final items = [_audio('a'), _video('v'), _audio('b')];
      final result = playableQueue(items, startIndex: 1);
      expect(result.items.map((i) => i.id), ['a', 'b']);
      expect(result.index, 0);
    });

    test('an all-video queue resolves to nothing to play', () {
      final result = playableQueue([_video('v'), _video('w')]);
      expect(result.items, isEmpty);
      expect(result.index, 0);
    });

    test('an out-of-range start index does not throw', () {
      final result = playableQueue([_audio('a')], startIndex: 9);
      expect(result.items.map((i) => i.id), ['a']);
      expect(result.index, 0);
    });

    test('a whitespace-only audio url counts as no audio', () {
      final items = [_pirith('w', audioUrl: '   '), _audio('a')];
      final result = playableQueue(items);
      expect(result.items.map((i) => i.id), ['a']);
    });
  });
}
