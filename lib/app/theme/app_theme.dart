import 'package:flutter/material.dart';

/// Light/dark themes for Pirith Potha. Palette is a placeholder calm
/// green/gold pairing fitting a devotional app; revisit during UI polish.
abstract final class AppTheme {
  static const _seedColor = Color(0xFF2E7D5B);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      );
}
