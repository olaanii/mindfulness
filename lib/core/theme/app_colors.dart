import 'package:flutter/material.dart';

/// Warm wellness palette (reference-aligned).
abstract final class AppColors {
  static const Color background = Color(0xFFFFFBF2);
  static const Color surface = Color(0xFFFFF8ED);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color primaryYellow = Color(0xFFF5D547);
  static const Color primaryYellowPressed = Color(0xFFE8C73A);
  static const Color onPrimaryYellow = Color(0xFF2B2410);
  static const Color accentCoral = Color(0xFFE07A5F);
  static const Color accentCoralMuted = Color(0xFFF2A090);
  static const Color outlineMuted = Color(0xFFC9B8A8);
  static const Color textPrimary = Color(0xFF2B2410);
  static const Color textSecondary = Color(0xFF6B5E52);

  static const double radiusLg = 24;
  static const double radiusMd = 16;

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF8B7355).withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
