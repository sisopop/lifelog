import 'package:flutter/material.dart';

/// Design tokens — derived from the MVP UI sample (purple accent, soft surfaces).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF8B7CF6);
  static const Color primaryDark = Color(0xFF6F5FE0);
  static const Color primarySoft = Color(0xFFEDE9FE);

  // Surfaces
  static const Color background = Color(0xFFF6F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8E6F0);

  // Text
  static const Color textPrimary = Color(0xFF1F1B2E);
  static const Color textSecondary = Color(0xFF6E6A7C);
  static const Color textHint = Color(0xFFAEAAB8);

  // Mood
  static const Color moodGood = Color(0xFF7CC4A4);
  static const Color moodNeutral = Color(0xFFC8C8D0);
  static const Color moodHard = Color(0xFFE59AAE);
}
