import 'package:flutter/material.dart';
import 'package:mindfulness/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: AppColors.primaryYellow,
      onPrimary: AppColors.onPrimaryYellow,
      primaryContainer: AppColors.primaryYellow.withValues(alpha: 0.35),
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accentCoral,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentCoralMuted.withValues(alpha: 0.25),
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.accentMint,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accentMint.withValues(alpha: 0.28),
      onTertiaryContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceMuted,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outlineMuted,
      outlineVariant: AppColors.outlineMuted.withValues(alpha: 0.5),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );

    final textTheme = Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          displayMedium: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          headlineLarge: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
          ),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          titleLarge: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
          ),
          titleMedium: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
          titleSmall: const TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: const TextStyle(height: 1.45),
          bodyMedium: const TextStyle(height: 1.45),
          labelLarge: const TextStyle(fontWeight: FontWeight.w700),
          labelMedium: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textBrand,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.glassPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.onPrimaryYellow,
          disabledBackgroundColor: AppColors.outlineMuted.withValues(
            alpha: 0.4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
          textStyle: textTheme.titleSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(
            color: AppColors.outlineMuted.withValues(alpha: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: textTheme.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassPanel,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.outlineMuted,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.outlineMuted.withValues(alpha: 0.35),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.outlineMuted.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.accentCoral, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 82,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primaryYellow.withValues(alpha: 0.45),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.textBrand : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.textBrand : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryYellow,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.textPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineMuted.withValues(alpha: 0.35),
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textBrand,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryYellow,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
