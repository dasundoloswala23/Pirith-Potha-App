import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// The UI shows Sinhala and English *together* rather than switching between
/// them (see docs/08_ui_ux.md) — a screen header reads "සැකසුම්" with
/// "Settings" beneath it, a Pirith card shows its Sinhala name above the
/// English one. Screens therefore need both translations of the same key at
/// once, which `AppLocalizations.of(context)` alone can't give.
///
/// Both ARB files are complete and kept in sync, so this just pairs them.
/// [AppLocalizations.of] still returns the active locale and stays the right
/// choice for anything shown in one language only.
class Bilingual {
  Bilingual._(this.si, this.en);

  static final Bilingual instance = Bilingual._(
    lookupAppLocalizations(const Locale('si')),
    lookupAppLocalizations(const Locale('en')),
  );

  static Bilingual of(BuildContext context) => instance;

  final AppLocalizations si;
  final AppLocalizations en;
}
