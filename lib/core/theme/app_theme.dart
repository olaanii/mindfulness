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
      tertiary: const Color(0xFF7EB6A8),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFB8D9CF),
      onTertiaryContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surface,
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
          titleLarge: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: const TextStyle(fontWeight: FontWeight.w600),
          headlineSmall: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
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
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.onPrimaryYellow,
          disabledBackgroundColor: AppColors.outlineMuted.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentCoral,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.accentCoral, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryYellow.withValues(alpha: 0.45),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.accentCoral : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accentCoral : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedColor: AppColors.primaryYellow.withValues(alpha: 0.5),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        side: BorderSide(color: AppColors.outlineMuted.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentCoral,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outlineMuted.withValues(alpha: 0.35),
        thickness: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.accentCoral,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accentCoral,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
