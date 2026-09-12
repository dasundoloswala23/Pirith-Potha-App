import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_localizations.dart';
import 'language_cubit.dart';

/// The UI shows Sinhala and English *together* rather than switching between
/// them (see docs/08_ui_ux.md) — a screen header reads "සැකසුම්" with
/// "Settings" beneath it, a Pirith card shows its Sinhala name above the
/// English one. Screens therefore need both translations of the same key at
/// once, which `AppLocalizations.of(context)` alone can't give.
///
/// [primary] and [secondary] follow the user's leading-language choice from
/// [LanguageCubit]; [si] and [en] name the languages directly, which is what
/// font selection needs — the Sinhala serif face must follow the Sinhala
/// text whichever line it lands on.
///
/// Both ARB files are complete and kept in sync, so this just pairs them.
class Bilingual {
  const Bilingual._(this.si, this.en, this.sinhalaFirst);

  static final _si = lookupAppLocalizations(const Locale('si'));
  static final _en = lookupAppLocalizations(const Locale('en'));

  /// Watches [LanguageCubit], so flipping the leading language rebuilds
  /// every screen that reads this.
  ///
  /// **Only valid inside `build`.** `context.watch` asserts when called from
  /// an event handler; use [read] there instead.
  static Bilingual of(BuildContext context) =>
      Bilingual._(_si, _en, context.watch<LanguageCubit>().state);

  /// Same pairing without subscribing, for event handlers — opening a
  /// dialog or sheet, building a SnackBar. Nothing there needs to rebuild
  /// when the leading language changes, and [of] would assert.
  static Bilingual read(BuildContext context) =>
      Bilingual._(_si, _en, context.read<LanguageCubit>().state);

  final AppLocalizations si;
  final AppLocalizations en;
  final bool sinhalaFirst;

  AppLocalizations get primary => sinhalaFirst ? si : en;
  AppLocalizations get secondary => sinhalaFirst ? en : si;

  /// Orders a Sinhala/English pair by the current preference.
  (String primary, String secondary) order(String sinhala, String english) =>
      sinhalaFirst ? (sinhala, english) : (english, sinhala);
}
