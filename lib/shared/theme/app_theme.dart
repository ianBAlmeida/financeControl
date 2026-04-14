import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: _colorScheme,
      textTheme: _textTheme(base),
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme(base),
      dividerColor: AppColors.border,
      snackBarTheme: _snackBarTheme,
      floatingActionButtonTheme: _fabTheme,
      progressIndicatorTheme: _progressTheme,
    );
  }

  static const _colorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.primarySoft,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  static TextTheme _textTheme(ThemeData base) => base.textTheme.apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );

  static const _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: AppColors.textPrimary,
    centerTitle: true,
  );

  static final _cardTheme = CardThemeData(
    color: AppColors.surface.withValues(alpha: 0.92),
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      side: const BorderSide(color: AppColors.border),
    ),
  );

  static final _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceSoft,
    border: _inputBorder(AppColors.border),
    enabledBorder: _inputBorder(AppColors.border),
    focusedBorder: _inputBorder(AppColors.primarySoft),
  );

  static ChipThemeData _chipTheme(ThemeData base) => base.chipTheme.copyWith(
    selectedColor: AppColors.primary.withValues(alpha: 0.25),
    backgroundColor: AppColors.surfaceSoft,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: AppColors.border),
    ),
    labelStyle: const TextStyle(color: AppColors.textPrimary),
    secondaryLabelStyle: const TextStyle(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
  );

  static const _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: AppColors.surfaceSoft,
    contentTextStyle: TextStyle(color: AppColors.textPrimary),
  );

  static const _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  );

  static const _progressTheme = ProgressIndicatorThemeData(
    color: AppColors.primarySoft,
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
    borderSide: BorderSide(color: color),
  );
}
