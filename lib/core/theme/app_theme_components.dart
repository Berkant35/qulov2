part of 'app_theme.dart';

// AppBar
final _appBarTheme = AppBarTheme(
  backgroundColor: AppColors.scaffold,
  foregroundColor: AppColors.textPrimary,
  elevation: 0,
  centerTitle: true,
  titleTextStyle: AppTextStyles.darkTextTheme.titleLarge?.copyWith(
    color: AppColors.textPrimary,
  ),
);

// Elevated Button (primary action - purple)
final _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryDark,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    elevation: 0,
  ),
);

// Outlined Button
final _outlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    side: const BorderSide(color: AppColors.primary),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  ),
);

// Text Button
final _textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  ),
);

// Input Decoration
final _inputDecorationTheme = InputDecorationTheme(
  filled: true,
  fillColor: AppColors.surfaceInput,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: const BorderSide(color: AppColors.error),
  ),
  errorMaxLines: 2,
  errorStyle: const TextStyle(
    color: AppColors.error,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  hintStyle: const TextStyle(color: AppColors.textHint),
  labelStyle: const TextStyle(color: AppColors.textSecondary),
);

// Card
final _cardTheme = CardThemeData(
  color: AppColors.surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    side: const BorderSide(color: AppColors.border, width: 0.5),
  ),
  margin: EdgeInsets.zero,
);

// Bottom Nav
const _bottomNavTheme = BottomNavigationBarThemeData(
  backgroundColor: AppColors.surface,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textHint,
  type: BottomNavigationBarType.fixed,
  elevation: 0,
);

// Navigation Bar
final _navigationBarTheme = NavigationBarThemeData(
  backgroundColor: AppColors.surface,
  indicatorColor: AppColors.primarySurface,
  elevation: 0,
  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
  iconTheme: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const IconThemeData(color: AppColors.primary);
    }
    return const IconThemeData(color: AppColors.textHint);
  }),
);

// Chip
final _chipTheme = ChipThemeData(
  backgroundColor: AppColors.surface,
  selectedColor: AppColors.primarySurface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
  ),
  side: const BorderSide(color: AppColors.border),
  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
);

// Dialog
final _dialogTheme = DialogThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
  ),
  backgroundColor: AppColors.surfaceElevated,
  titleTextStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
  contentTextStyle: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  ),
);

// SnackBar
final _snackBarTheme = SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
  ),
  backgroundColor: AppColors.surfaceElevated,
  contentTextStyle: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  ),
);

// ═══════════════════════════════════════════════════════════════════════════
// LIGHT THEME COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

// AppBar Light
const _appBarThemeLight = AppBarTheme(
  backgroundColor: AppColorsLight.scaffold,
  foregroundColor: AppColorsLight.textPrimary,
  elevation: 0,
  centerTitle: true,
  titleTextStyle: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textPrimary,
  ),
);

// TextField Light
final _inputDecorationThemeLight = InputDecorationTheme(
  filled: true,
  fillColor: AppColorsLight.surfaceInput,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: BorderSide.none,
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: const BorderSide(color: AppColors.primary, width: 2),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: const BorderSide(color: AppColors.error),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    borderSide: const BorderSide(color: AppColors.error, width: 2),
  ),
  errorMaxLines: 2,
  hintStyle: const TextStyle(color: AppColorsLight.textHint),
  labelStyle: const TextStyle(color: AppColorsLight.textSecondary),
  errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
);

// Card Light
final _cardThemeLight = CardThemeData(
  color: AppColorsLight.surfaceElevated,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    side: const BorderSide(color: AppColorsLight.border, width: 0.5),
  ),
  margin: EdgeInsets.zero,
);

// BottomNav Light
const _bottomNavThemeLight = BottomNavigationBarThemeData(
  backgroundColor: AppColorsLight.scaffold,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColorsLight.textHint,
  type: BottomNavigationBarType.fixed,
  elevation: 0,
);

// NavigationBar Light
final _navigationBarThemeLight = NavigationBarThemeData(
  backgroundColor: AppColorsLight.scaffold,
  indicatorColor: AppColors.primarySurface,
  elevation: 0,
  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
  iconTheme: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const IconThemeData(color: AppColors.primary);
    }
    return const IconThemeData(color: AppColorsLight.textHint);
  }),
  labelTextStyle: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
      );
    }
    return const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      color: AppColorsLight.textHint,
    );
  }),
);

// Chip Light
final _chipThemeLight = ChipThemeData(
  backgroundColor: AppColorsLight.surface,
  selectedColor: AppColors.primarySurface,
  side: const BorderSide(color: AppColorsLight.border),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
  ),
  labelStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColorsLight.textPrimary,
  ),
);

// Dialog Light
final _dialogThemeLight = DialogThemeData(
  backgroundColor: AppColorsLight.surfaceElevated,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
  ),
  titleTextStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColorsLight.textPrimary,
  ),
  contentTextStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColorsLight.textSecondary,
  ),
);

// SnackBar Light
final _snackBarThemeLight = SnackBarThemeData(
  backgroundColor: AppColorsLight.textPrimary,
  contentTextStyle: const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: AppColorsLight.scaffold,
  ),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
  ),
);
