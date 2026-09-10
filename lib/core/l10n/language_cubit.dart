import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which language leads in the bilingual UI.
///
/// Both languages are always shown (see docs/08_ui_ux.md) — this only
/// decides which one is the large/primary line and which is the smaller
/// one beneath it, so nothing is ever hidden by the choice.
class LanguageCubit extends Cubit<bool> {
  LanguageCubit(this._prefs) : super(_prefs.getBool(_key) ?? true);

  static const _key = 'sinhala_first';

  final SharedPreferences _prefs;

  /// `true` when Sinhala is the leading language.
  bool get sinhalaFirst => state;

  Future<void> setSinhalaFirst(bool value) async {
    if (value == state) return;
    emit(value);
    await _prefs.setBool(_key, value);
  }
}
