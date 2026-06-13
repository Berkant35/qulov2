import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Background & Surface ───
  static const background = Color(0xFF0D0D0D);
  static const scaffold = Color(0xFF121212);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF242424);
  static const surfaceInput = Color(0xFF2A2A2A);

  // ─── Primary (Mor Neon) ───
  static const primary = Color(0xFFBB86FC);
  static const primaryDark = Color(0xFF9C27B0);
  static const primaryLight = Color(0xFFE1BEE7);
  static const primarySurface = Color(0x1ABB86FC);

  // ─── Secondary (Yesil Neon) ───
  static const secondary = Color(0xFF69F0AE);
  static const secondaryDark = Color(0xFF4CAF50);
  static const secondaryLight = Color(0xFFB9F6CA);
  static const secondarySurface = Color(0x1A69F0AE);

  // ─── Semantic ───
  static const error = Color(0xFFCF6679);
  static const success = Color(0xFF69F0AE);
  static const warning = Color(0xFFFFB74D);
  static const info = Color(0xFF64B5F6);

  // ─── Text ───
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textHint = Color(0xFF666666);

  // ─── Border & Divider ───
  static const border = Color(0xFF2A2A2A);
  static const divider = Color(0xFF2A2A2A);

  // ─── Badge ───
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // ─── Difficulty ───
  static const Color hardOrange = Color(0xFFFF7043);

  // ─── Quiz Badge Gradients ───
  static const Color amber = Color(0xFFFFC107);
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color green = Color(0xFF4CAF50);
  static const Color teal = Color(0xFF009688);
  static const Color pink = Color(0xFFE91E63);
  static const Color red = Color(0xFFF44336);

  // ─── Scrim / Overlay ───
  /// Semi-transparent dark scrim — used for blur overlays, lock icons, etc.
  static const scrimDark = Color(0x80000000); // black 50%
  static const scrimLight = Color(0x33000000); // black 20%
  /// Icon/text color placed on top of a dark scrim
  static const onScrim = Color(0xFFFFFFFF);
  static const onScrimSubtle = Color(0xCCFFFFFF); // white 80%

  // ─── Gradients ───
  static const purpleGradient = LinearGradient(
    colors: [Color(0xFFBB86FC), Color(0xFF9C27B0)],
  );

  static const greenGradient = LinearGradient(
    colors: [Color(0xFF69F0AE), Color(0xFF4CAF50)],
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
  );
}

/// Brightness-aware color accessor via BuildContext.
/// Usage: `context.appColors.surface` instead of `AppColors.surface`
extension AppColorsOf on BuildContext {
  AppColorsResolved get appColors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.light
        ? AppColorsResolved.light
        : AppColorsResolved.dark;
  }
}

class AppColorsResolved {
  // ─── Surface ───
  final Color background;
  final Color scaffold;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInput;

  // ─── Accent ───
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color primarySurface;
  final Color secondary;
  final Color secondaryDark;
  final Color secondaryLight;
  final Color secondarySurface;

  // ─── Semantic ───
  final Color error;
  final Color success;
  final Color warning;
  final Color info;

  // ─── Text ───
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // ─── Border & Divider ───
  final Color border;
  final Color divider;

  // ─── Gradients ───
  final LinearGradient purpleGradient;
  final LinearGradient greenGradient;
  final LinearGradient primaryButtonGradient;

  const AppColorsResolved({
    required this.background,
    required this.scaffold,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInput,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.primarySurface,
    required this.secondary,
    required this.secondaryDark,
    required this.secondaryLight,
    required this.secondarySurface,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.purpleGradient,
    required this.greenGradient,
    required this.primaryButtonGradient,
  });

  static const dark = AppColorsResolved(
    background: AppColors.background,
    scaffold: AppColors.scaffold,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    surfaceInput: AppColors.surfaceInput,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    primarySurface: AppColors.primarySurface,
    secondary: AppColors.secondary,
    secondaryDark: AppColors.secondaryDark,
    secondaryLight: AppColors.secondaryLight,
    secondarySurface: AppColors.secondarySurface,
    error: AppColors.error,
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    border: AppColors.border,
    divider: AppColors.divider,
    purpleGradient: AppColors.purpleGradient,
    greenGradient: AppColors.greenGradient,
    primaryButtonGradient: AppColors.primaryButtonGradient,
  );

  /// Light mode: deeper, more saturated accents for white backgrounds
  static const light = AppColorsResolved(
    background: AppColorsLight.background,
    scaffold: AppColorsLight.scaffold,
    surface: AppColorsLight.surface,
    surfaceElevated: AppColorsLight.surfaceElevated,
    surfaceInput: AppColorsLight.surfaceInput,
    // Deeper purple for white bg (WCAG AA contrast)
    primary: Color(0xFF7B1FA2),
    primaryDark: Color(0xFF6A1B9A),
    primaryLight: Color(0xFFCE93D8),
    primarySurface: Color(0x1A7B1FA2),
    // Deeper green for white bg
    secondary: Color(0xFF2E7D32),
    secondaryDark: Color(0xFF1B5E20),
    secondaryLight: Color(0xFF81C784),
    secondarySurface: Color(0x1A2E7D32),
    // Stronger semantic colors for light bg
    error: Color(0xFFD32F2F),
    success: Color(0xFF2E7D32),
    warning: Color(0xFFE65100),
    info: Color(0xFF1565C0),
    textPrimary: AppColorsLight.textPrimary,
    textSecondary: AppColorsLight.textSecondary,
    textHint: AppColorsLight.textHint,
    border: AppColorsLight.border,
    divider: AppColorsLight.divider,
    purpleGradient: LinearGradient(
      colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
    ),
    greenGradient: LinearGradient(
      colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
    ),
    primaryButtonGradient: LinearGradient(
      colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
    ),
  );
}

/// Light theme colors — warm off-white palette for comfortable reading
abstract final class AppColorsLight {
  // ─── Background & Surface ───
  static const background = Color(0xFFF5F0EB);  // warm cream
  static const scaffold = Color(0xFFF8F4F0);     // soft warm white
  static const surface = Color(0xFFF0EBE5);      // warm surface
  static const surfaceElevated = Color(0xFFFAF7F4); // slightly lifted
  static const surfaceInput = Color(0xFFEDE7E1);    // warm input bg

  // ─── Text ───
  static const textPrimary = Color(0xFF1C1917);   // warm black
  static const textSecondary = Color(0xFF57534E);  // warm gray (better contrast)
  static const textHint = Color(0xFF8C8680);       // warm hint

  // ─── Border & Divider ───
  static const border = Color(0xFFD6D0CA);         // warm border
  static const divider = Color(0xFFD6D0CA);
}
