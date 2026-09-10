import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font choices from the approved UI reference:
/// - Sinhala titles/headings: Noto Serif Sinhala
/// - Sinhala UI/body text: Noto Sans Sinhala
/// - English serif accents (subtitles, quotes): Lora
/// - English UI/body text: Inter
///
/// Fonts are fetched via `google_fonts` (cached on-device after first use)
/// rather than bundled as assets — see the TODO this replaces in
/// pubspec.yaml. If guaranteed-offline-on-first-run typography becomes a
/// requirement, switch to google_fonts' bundled-asset mode then.
abstract final class AppTypography {
  static TextStyle sinhalaTitle({double fontSize = 16, FontWeight? weight, Color? color}) =>
      GoogleFonts.notoSerifSinhala(
        fontSize: fontSize,
        fontWeight: weight ?? FontWeight.w600,
        color: color,
      );

  static TextStyle sinhalaBody({double fontSize = 14, FontWeight? weight, Color? color}) =>
      GoogleFonts.notoSansSinhala(fontSize: fontSize, fontWeight: weight, color: color);

  static TextStyle englishSerif({
    double fontSize = 14,
    FontStyle fontStyle = FontStyle.normal,
    FontWeight? weight,
    Color? color,
  }) =>
      GoogleFonts.lora(
        fontSize: fontSize,
        fontStyle: fontStyle,
        fontWeight: weight,
        color: color,
      );

  static TextTheme textTheme(Color bodyColor) =>
      GoogleFonts.interTextTheme().apply(bodyColor: bodyColor, displayColor: bodyColor);
}
