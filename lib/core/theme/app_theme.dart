import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // ── Shared Constants ──────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusFull = 50.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingXL = 24.0;

  static const double inputHeight = 56.0;
  static const double buttonHeight = 56.0;

  // ══════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Cairo',

    // ── Color Scheme ────────────────────────
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.goldLight10,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.goldLight10,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      surfaceContainerHighest: AppColors.lightBackground,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.lightBorder,
      shadow: AppColors.lightCardShadow,
    ),

    scaffoldBackgroundColor: AppColors.lightBackground,

    // ── AppBar ──────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ── Card ────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shadowColor: AppColors.lightCardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Elevated Button ─────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, buttonHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        elevation: 0,
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Outlined Button ─────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, buttonHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Text Button ─────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelMedium,
      ),
    ),

    // ── Input Decoration ────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.lightTextSecondary,
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.lightTextSecondary,
      ),
      prefixIconColor: AppColors.lightTextSecondary,
      suffixIconColor: AppColors.lightTextSecondary,
    ),

    // ── Bottom Navigation Bar ───────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextSecondary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ── Chip ────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightBackground,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.lightText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      side: const BorderSide(color: AppColors.lightBorder),
    ),

    // ── Divider ─────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: 1,
    ),

    // ── Switch ──────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.lightTextSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.lightBorder;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.lightTextSecondary.withValues(alpha: 0.4);
      }),
    ),

    // ── Dialog ──────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.lightText,
      ),
    ),

    // ── SnackBar ─────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Text ─────────────────────────────────
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: AppColors.lightText,
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: AppColors.lightText,
      ),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(
        color: AppColors.lightText,
      ),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.lightText,
      ),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.lightText,
      ),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.lightText),
      titleMedium: AppTextStyles.titleMedium.copyWith(
        color: AppColors.lightText,
      ),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.lightText),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.lightText),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightText),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: AppColors.lightTextSecondary,
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.lightText),
      labelMedium: AppTextStyles.labelMedium.copyWith(
        color: AppColors.lightText,
      ),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: AppColors.lightTextSecondary,
      ),
    ),
  );

  // ══════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',

    // ── Color Scheme ────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.goldDark10,
      secondary: AppColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.goldDark10,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      surfaceContainerHighest: AppColors.darkBackground,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.darkBorder,
      shadow: AppColors.darkCardShadow,
    ),

    scaffoldBackgroundColor: AppColors.darkBackground,

    // ── AppBar ──────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      iconTheme: IconThemeData(color: AppColors.darkText),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ── Card ────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shadowColor: AppColors.darkCardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Elevated Button ─────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, buttonHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        elevation: 0,
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Outlined Button ─────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, buttonHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        textStyle: AppTextStyles.labelLarge,
      ),
    ),

    // ── Text Button ─────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.labelMedium,
      ),
    ),

    // ── Input Decoration ────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceAlt,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMedium,
        vertical: paddingMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      prefixIconColor: AppColors.darkTextSecondary,
      suffixIconColor: AppColors.darkTextSecondary,
    ),

    // ── Bottom Navigation Bar ───────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextSecondary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ── Chip ────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceAlt,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.darkText),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      side: const BorderSide(color: AppColors.darkBorder),
    ),

    // ── Divider ─────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: 1,
      space: 1,
    ),

    // ── Switch ──────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.darkTextSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.darkBorder;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return AppColors.darkTextSecondary.withValues(alpha: 0.35);
      }),
    ),

    // ── Dialog ──────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXL),
      ),
      titleTextStyle: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.darkText,
      ),
    ),

    // ── SnackBar ─────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceAlt,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Text ─────────────────────────────────
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: AppColors.darkText,
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: AppColors.darkText,
      ),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(
        color: AppColors.darkText,
      ),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(
        color: AppColors.darkText,
      ),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(
        color: AppColors.darkText,
      ),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.darkText),
      titleMedium: AppTextStyles.titleMedium.copyWith(
        color: AppColors.darkText,
      ),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.darkText),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkText),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.darkText),
      labelMedium: AppTextStyles.labelMedium.copyWith(
        color: AppColors.darkText,
      ),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    ),
  );
}
