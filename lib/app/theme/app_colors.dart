import 'package:flutter/material.dart';

/// Warm devotional palette (cream/tan light, deep brown dark, marigold-gold
/// accent), taken from the approved Figma Make UI reference at
/// `Buddhist Audio App UI Design/src/index.css` — keep these two in sync if
/// the reference changes.
abstract final class AppColors {
  // Light theme
  static const lightBackground = Color(0xFFFAF3E3);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceRaised = Color(0xFFF4EAD4);
  static const lightTextPrimary = Color(0xFF1C0C00);
  static const lightTextSecondary = Color(0xFF7A5530);
  static const lightTextTertiary = Color(0xFFB89060);
  static const lightBorder = Color(0xFFE5D0A8);
  static const lightBorder2 = Color(0xFFF0E4C8);
  static const lightGoldSurface = Color(0xFFFDF5DE);
  static const lightMaroonSurface = Color(0xFFFBF0F0);
  static const lightNav = Color(0xFFFFFFFF);

  // Dark theme
  static const darkBackground = Color(0xFF0C0700);
  static const darkSurface = Color(0xFF1A1005);
  static const darkSurfaceRaised = Color(0xFF221505);
  static const darkTextPrimary = Color(0xFFF5EBCF);
  static const darkTextSecondary = Color(0xFFC09060);
  static const darkTextTertiary = Color(0xFF7A6040);
  static const darkBorder = Color(0xFF3A2208);
  static const darkBorder2 = Color(0xFF2A1808);
  static const darkGoldSurface = Color(0xFF1C1205);
  static const darkMaroonSurface = Color(0xFF280A0A);
  static const darkNav = Color(0xFF1A1005);

  // Shared accent + semantic colors (same in both themes, per reference)
  static const gold = Color(0xFFC07C18);
  static const gold2 = Color(0xFFEDB94A);
  static const goldDark = Color(0xFFD49A28); // dark-mode gold variant
  static const gold2Dark = Color(0xFFF0C060);
  static const maroon = Color(0xFF8B2020);
  static const maroonDark = Color(0xFFC04040);
  static const green = Color(0xFF3D7050);
  static const onAccent = Color(0xFFFFFFFF);

  // Full-screen player (always dark, regardless of app theme)
  static const player = Color(0xFF120900);
  static const playerSurface = Color(0xFF1E1008);
  static const playerText = Color(0xFFF5EBCF);
  static const playerTextSecondary = Color(0xFFC09050);

  /// Category card gradients (start, end), in the fixed order the product
  /// defines categories — see docs/03_database_schema.md `categories`.
  static const categoryGradients = <(Color, Color)>[
    (Color(0xFF7C2020), Color(0xFFC04040)), // protective
    (Color(0xFFB8780E), Color(0xFFE0A830)), // metta
    (Color(0xFF2A6040), Color(0xFF4A9060)), // blessings
    (Color(0xFF5B4FA0), Color(0xFF8070C0)), // morning
    (Color(0xFF2A6080), Color(0xFF4090B0)), // healing
    (Color(0xFF804030), Color(0xFFC07050)), // evening
  ];

  /// Pirith artwork background colors, rotated by id when no real cover art
  /// exists yet.
  static const artworkPalette = <Color>[
    Color(0xFF8B4513),
    Color(0xFF7C2020),
    Color(0xFF2A5A40),
    Color(0xFF4A5A90),
    Color(0xFF5A3A80),
    Color(0xFF805A20),
    Color(0xFF205A60),
    Color(0xFF6B4A10),
  ];

  static (Color, Color) categoryGradientFor(int index) =>
      categoryGradients[index % categoryGradients.length];

  /// Picks a stable artwork color from a Pirith's id.
  ///
  /// Keyed on the id rather than a list position so one Pirith keeps the same
  /// color everywhere it appears — Home, search results, the player — and
  /// across app launches. `String.hashCode` isn't guaranteed stable between
  /// Dart versions, so this uses FNV-1a explicitly.
  static Color artworkColorForId(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return artworkPalette[hash % artworkPalette.length];
  }
}
