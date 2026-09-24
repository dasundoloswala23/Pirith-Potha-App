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
      expect(isOutdated(installed: '1.00.02', latest: 'not-a-version'), isFalse);
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
}
