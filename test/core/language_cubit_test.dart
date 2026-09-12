import 'package:flutter_test/flutter_test.dart';
import 'package:pitithpotha/core/l10n/language_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageCubit', () {
    test('leads in English on a fresh install', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = LanguageCubit(await SharedPreferences.getInstance());
      addTearDown(cubit.close);

      expect(cubit.sinhalaFirst, isFalse);
    });

    test('a switch to Sinhala survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = LanguageCubit(prefs);
      await first.setSinhalaFirst(true);
      await first.close();

      // A second cubit over the same store is what a relaunch looks like.
      final second = LanguageCubit(prefs);
      addTearDown(second.close);

      expect(second.sinhalaFirst, isTrue);
    });

    test('switching back to English is remembered too', () async {
      SharedPreferences.setMockInitialValues({'sinhala_first': true});
      final prefs = await SharedPreferences.getInstance();

      final first = LanguageCubit(prefs);
      expect(first.sinhalaFirst, isTrue);
      await first.setSinhalaFirst(false);
      await first.close();

      final second = LanguageCubit(prefs);
      addTearDown(second.close);

      // Explicitly false, not "absent and defaulted" — the distinction
      // matters if the default ever changes again.
      expect(prefs.getBool('sinhala_first'), isFalse);
      expect(second.sinhalaFirst, isFalse);
    });
  });
}
