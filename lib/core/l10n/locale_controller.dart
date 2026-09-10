import 'package:flutter/material.dart';

/// Holds the user's active app language (Sinhala/English) so it can be
/// switched at runtime from Settings/Profile. Persisting the choice to local
/// storage (and to `users/{uid}.languagePreference` once authenticated) is
/// added in the Firebase/auth phases — see docs/08_ui_ux.md.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController(super._value);

  static const english = Locale('en');
  static const sinhala = Locale('si');

  void setEnglish() => value = english;

  void setSinhala() => value = sinhala;

  void toggle() => value = value == sinhala ? english : sinhala;
}
