import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() => _base(brightness: Brightness.dark);

  static ThemeData light() => _base(brightness: Brightness.light);

  static ThemeData _base({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.villagePurple,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.villageGreen,
          secondary: AppColors.villagePurple,
          tertiary: AppColors.villageCyan,
          surface: isDark ? AppColors.villagePanel : Colors.white,
          onSurface: isDark ? AppColors.villageText : Colors.black87,
        );

    final headingColor = isDark
        ? AppColors.villagePurpleDeep.withValues(alpha: 0.45)
        : const Color(0xFFF3F4F6);
    final headingTextColor = isDark
        ? AppColors.villageGreen
        : AppColors.villagePurpleDeep;
    final dataTextColor = isDark ? AppColors.villageText : Colors.black87;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.villageBlack : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.villagePanel : Colors.white,
        foregroundColor: isDark
            ? AppColors.villageText
            : AppColors.villagePurpleDeep,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.villagePanel : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? AppColors.villagePurple.withValues(alpha: 0.25)
                : AppColors.villagePurpleDeep.withValues(alpha: 0.15),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.villageGreen,
          foregroundColor: AppColors.villageBlack,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.villageCyan
              : AppColors.villagePurple,
          side: BorderSide(
            color: isDark
                ? AppColors.villagePurple
                : AppColors.villagePurpleDeep,
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(headingColor),
        dataRowMinHeight: 72,
        dataRowMaxHeight: 72,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: headingTextColor,
          fontSize: 13,
        ),
        dataTextStyle: TextStyle(color: dataTextColor, fontSize: 13),
      ),
    );
  }

  static const defaultDataRowHeight = 72.0;
}
