import 'package:flutter/material.dart';

import 'package:qulo_v2/core/theme/app_colors.dart';
import 'package:qulo_v2/core/theme/app_spacing.dart';
import 'package:qulo_v2/core/theme/app_text_styles.dart';

part 'app_theme_components.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.black,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          error: AppColors.error,
          onError: Colors.white,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          surfaceContainerHighest: AppColors.surfaceInput,
        ),
        textTheme: AppTextStyles.darkTextTheme,
        scaffoldBackgroundColor: AppColors.scaffold,
        dividerColor: AppColors.divider,
        appBarTheme: _appBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        bottomNavigationBarTheme: _bottomNavTheme,
        navigationBarTheme: _navigationBarTheme,
        chipTheme: _chipTheme,
        dialogTheme: _dialogTheme,
        snackBarTheme: _snackBarTheme,
        switchTheme: _switchTheme,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.surfaceInput,
          linearMinHeight: 4,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        textTheme: AppTextStyles.lightTextTheme,
        colorScheme: ColorScheme.light(
          primary: AppColorsResolved.light.primary,
          onPrimary: Colors.white,
          secondary: AppColorsResolved.light.secondary,
          onSecondary: Colors.white,
          surface: AppColorsLight.surface,
          onSurface: AppColorsLight.textPrimary,
          error: AppColorsResolved.light.error,
          onError: Colors.white,
          outline: AppColorsLight.border,
          outlineVariant: AppColorsLight.border,
          surfaceContainerHighest: AppColorsLight.surfaceInput,
        ),
        scaffoldBackgroundColor: AppColorsLight.scaffold,
        dividerColor: AppColorsLight.divider,
        appBarTheme: _appBarThemeLight,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationThemeLight,
        cardTheme: _cardThemeLight,
        bottomNavigationBarTheme: _bottomNavThemeLight,
        navigationBarTheme: _navigationBarThemeLight,
        chipTheme: _chipThemeLight,
        dialogTheme: _dialogThemeLight,
        snackBarTheme: _snackBarThemeLight,
        switchTheme: _switchThemeLight,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: AppColorsResolved.light.primary,
          linearMinHeight: 4,
          linearTrackColor: AppColorsLight.surfaceInput,
        ),
      );
}
