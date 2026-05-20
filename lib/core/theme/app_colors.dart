import 'package:flutter/material.dart';

/// Warm wellness palette (reference-aligned).
abstract final class AppColors {
  static const Color background = Color(0xFFFFF9EE);
  static const Color surface = Color(0xFFFFF6E8);
  static const Color surfaceMuted = Color(0xFFF5EDDE);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color glassPanel = Color(0xCCFFFFFF);
  static const Color headerGlass = Color(0xB3FFF9EE);
  static const Color primaryYellow = Color(0xFFF5D547);
  static const Color primaryYellowSoft = Color(0x66F5D547);
  static const Color primaryYellowPressed = Color(0xFFE8C73A);
  static const Color onPrimaryYellow = Color(0xFF2B2410);
  static const Color accentCoral = Color(0xFFFC9174);
  static const Color accentCoralMuted = Color(0xFFF7C5B7);
  static const Color accentMint = Color(0xFF9AC7B3);
  static const Color outlineMuted = Color(0xFFCFC6AE);
  static const Color borderMuted = Color(0xFFCFC6AE);
  static const Color borderSoft = Color(0x337D7762);
  static const Color glassBorder = Color(0xCCFFFFFF);
  static const Color textPrimary = Color(0xFF1E1B12);
  static const Color textBrand = Color(0xFF6F5D00);
  static const Color textSecondary = Color(0xFF4C4734);
  static const Color textMuted = Color(0xFF7D7762);
  static const Color glowYellow = Color(0xFFF5D547);
  static const Color glowCoral = Color(0xFFFC9174);

  static const double radiusLg = 24;
  static const double radiusMd = 16;
  static const double radiusXl = 32;

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF6F5D00).withValues(alpha: 0.08),
        blurRadius: 30,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> elevatedGlow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.28)
            : primaryYellow.withValues(alpha: 0.22),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.18)
            : const Color(0xFF6F5D00).withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }
}
