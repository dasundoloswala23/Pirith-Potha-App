import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/utils/youtube_url.dart';

// The admin app applies no validation to this field, so these cases are not
// hypothetical — whatever an admin pastes is what the player receives.
void main() {
  const id = 'dQw4w9WgXcQ';

  group('youTubeVideoId resolves', () {
    final cases = <String, String>{
      'watch URL': 'https://www.youtube.com/watch?v=$id',
      'watch URL with extra params':
          'https://www.youtube.com/watch?v=$id&list=PLabc&index=2&t=30s',
      'watch URL with v last': 'https://www.youtube.com/watch?list=PLabc&v=$id',
      'short link': 'https://youtu.be/$id',
      'short link with timestamp': 'https://youtu.be/$id?t=42',
      'plain http': 'http://youtu.be/$id',
      'shorts': 'https://www.youtube.com/shorts/$id',
      'embed': 'https://www.youtube.com/embed/$id?rel=0',
      'old /v/ form': 'https://www.youtube.com/v/$id',
      'live': 'https://www.youtube.com/live/$id',
      'mobile host': 'https://m.youtube.com/watch?v=$id',
      'music host': 'https://music.youtube.com/watch?v=$id',
      'nocookie host': 'https://www.youtube-nocookie.com/embed/$id',
      'no scheme': 'youtube.com/watch?v=$id',
      'no scheme with www': 'www.youtube.com/watch?v=$id',
      'no scheme short link': 'youtu.be/$id',
      'surrounding whitespace': '  https://youtu.be/$id  ',
      'bare id': id,
    };

    cases.forEach((name, url) {
      test(name, () => expect(youTubeVideoId(url), id));
    });

    test('preserves id casing even when the host is shouted', () {
      // Only the host may be lowercased — ids are case-sensitive, so
      // lowercasing the whole string would silently return the wrong video.
      expect(youTubeVideoId('HTTPS://WWW.YOUTUBE.COM/watch?v=$id'), id);
    });

    test('keeps the - and _ characters that are legal in ids', () {
      expect(youTubeVideoId('https://youtu.be/a-b_cdefghi'), 'a-b_cdefghi');
    });
  });

  group('youTubeVideoId returns null for', () {
    final cases = <String, String>{
      'empty string': '',
      'whitespace only': '   ',
      'prose': 'not a youtube link at all',
      'another host borrowing the shape':
          'https://example.com/watch?v=$id',
      'a different video site': 'https://vimeo.com/12345',
      'the bare domain': 'https://www.youtube.com/',
      'watch with no v param': 'https://www.youtube.com/watch',
      'an id that is too short': 'https://www.youtube.com/watch?v=short',
      'an id that is too long':
          'https://www.youtube.com/watch?v=waytoolongforanid',
      'a playlist': 'https://www.youtube.com/playlist?list=PL123',
      'a channel': 'https://www.youtube.com/@somechannel',
      'illegal characters in the id': r'abc$defghij',
    };

    cases.forEach((name, url) {
      test(name, () => expect(youTubeVideoId(url), isNull));
    });
  });

  group('URL builders', () {
    // Pinned literals: these are contracts with an external service, so a
    // change to them should have to be deliberate.
    test('thumbnail', () {
      expect(youTubeThumbnailUrl(id), 'https://i.ytimg.com/vi/$id/maxresdefault.jpg');
    });

    test('fallback thumbnail', () {
      expect(
        youTubeFallbackThumbnailUrl(id),
        'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      );
    });

    test('watch', () {
      expect(youTubeWatchUrl(id), 'https://www.youtube.com/watch?v=$id');
    });
  });
}
