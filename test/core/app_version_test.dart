import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/utils/app_version.dart';

void main() {
  group('isOutdated', () {
    test('equal versions are not outdated', () {
      expect(isOutdated(installed: '1.00.02', latest: '1.00.02'), isFalse);
    });

    test('an older installed version is outdated', () {
      expect(isOutdated(installed: '1.00.02', latest: '1.00.03'), isTrue);
    });

    test('a newer installed version (pre-release build) is not outdated', () {
      expect(isOutdated(installed: '1.00.03', latest: '1.00.02'), isFalse);
    });

    test('compares components as integers, not strings', () {
      // "9" > "10" as strings, but 9 < 10 as integers.
      expect(isOutdated(installed: '1.9', latest: '1.10'), isTrue);
    });

    test('a missing trailing component counts as zero', () {
      expect(isOutdated(installed: '1.1', latest: '1.1.0'), isFalse);
      expect(isOutdated(installed: '1.1', latest: '1.1.1'), isTrue);
      expect(isOutdated(installed: '1.1.0', latest: '1.1'), isFalse);
    });

    test('a higher first component wins regardless of later components', () {
      expect(isOutdated(installed: '1.9.9', latest: '2.0.0'), isTrue);
    });

    test('malformed remote value fails safe: never claims outdated', () {
      expect(
        isOutdated(installed: '1.00.02', latest: 'not-a-version'),
        isFalse,
      );
      expect(isOutdated(installed: '1.00.02', latest: ''), isFalse);
      expect(isOutdated(installed: '1.00.02', latest: '1.x.2'), isFalse);
    });

    test('malformed installed value also fails safe', () {
      expect(isOutdated(installed: 'garbage', latest: '1.00.03'), isFalse);
    });

    test('surrounding whitespace is tolerated', () {
      expect(isOutdated(installed: ' 1.00.02 ', latest: '1.00.03'), isTrue);
    });
  });

  group('classifyUpdate', () {
    UpdateType c(String installed, String latest) =>
        classifyUpdate(installed: installed, latest: latest);

    test('newer patch is optional', () {
      expect(c('1.00.03', '1.00.04'), UpdateType.optional);
      expect(c('2.4.1', '2.4.9'), UpdateType.optional);
    });

    test('newer minor is mandatory, even with a lower patch', () {
      expect(c('1.00.03', '1.01.00'), UpdateType.mandatory);
      expect(c('2.4.9', '2.5.0'), UpdateType.mandatory);
    });

    test('newer major is mandatory, even with lower minor and patch', () {
      expect(c('1.00.03', '2.00.00'), UpdateType.mandatory);
      expect(c('1.9.9', '2.0.0'), UpdateType.mandatory);
    });

    test('equal or older remote means no update', () {
      expect(c('1.00.03', '1.00.03'), UpdateType.none);
      expect(c('1.00.04', '1.00.03'), UpdateType.none);
      expect(c('1.01.00', '1.00.09'), UpdateType.none);
      expect(c('2.0.0', '1.9.9'), UpdateType.none);
    });

    test('compares numerically, not as strings', () {
      expect(c('1.9.0', '1.10.0'), UpdateType.mandatory);
      expect(c('1.0.9', '1.0.10'), UpdateType.optional);
    });

    test('build numbers and whitespace are ignored', () {
      expect(c('1.00.03+3', '1.00.03+9'), UpdateType.none);
      expect(c(' 1.00.03+3 ', ' 1.00.04 '), UpdateType.optional);
    });

    test('missing segments count as zero', () {
      expect(c('1', '1.0.1'), UpdateType.optional);
      expect(c('1.0', '1.1'), UpdateType.mandatory);
    });

    test('malformed on either side fails open', () {
      for (final bad in ['', 'garbage', '1.x.0', '1.0.-1', 'v1.0.0']) {
        expect(c('1.00.03', bad), UpdateType.none, reason: 'latest "$bad"');
        expect(c(bad, '9.0.0'), UpdateType.none, reason: 'installed "$bad"');
      }
    });
  });
}
