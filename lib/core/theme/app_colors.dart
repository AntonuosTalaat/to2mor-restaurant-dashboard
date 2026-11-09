import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors (من اللوجو) ──────────────
  static const Color primary = Color(0xFFC19757); // الذهبي الرئيسي من اللوجو
  static const Color primaryDark = Color(0xFFA67C3B); // ذهبي داكن
  static const Color primaryLight = Color(0xFFD4AF7A); // ذهبي فاتح

  static const Color secondary = Color(0xFF9CA3AF); // الفضي من اللوجو
  static const Color secondaryDark = Color(0xFF6B7280); // فضي داكن
  static const Color secondaryLight = Color(0xFFD1D5DB); // فضي فاتح

  static const Color accent = Color(0xFFC19757); // لون التأكيد (ذهبي)
  static const Color gold = Color(0xFFC19757); // الذهبي
  static const Color silver = Color(0xFF9CA3AF); // الفضي

  // ── Semantic Colors ───────────────────────
  static const Color success = Color(0xFF38A169);
  static const Color error = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFFC19757);

  // ── Light Theme ───────────────────────────
  static const Color lightBackground = Color(0xFFFAF9F7); // بيج فاتح جداً
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF5F3F0); // بيج فاتح بديل
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFF0F0F0);
  static const Color lightCardShadow = Color(0x0A000000);
  static const Color lightOverlay = Color(0x0D000000);

  // ── Dark Theme (مستوحى من خلفية اللوجو) ────
  static const Color darkBackground = Color(0xFF0F0F0F); // أسود اللوجو
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceAlt = Color(0xFF242424);
  static const Color darkText = Color(0xFFFAF9F7);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF2D2D2D);
  static const Color darkDivider = Color(0xFF1F1F1F);
  static const Color darkCardShadow = Color(0x40000000);
  static const Color darkOverlay = Color(0x40000000);

  // ── Primary (Gold) Gradients & Tints ──────
  static const Color goldGradientStart = Color(0xFFD4AF7A);
  static const Color goldGradientEnd = Color(0xFFA67C3B);

  static const Color goldLight10 = Color(0xFFFAF8F5); // ذهبي فاتح جداً
  static const Color goldLight20 = Color(0xFFF0E9DC);
  static const Color goldLight30 = Color(0xFFE5D4B8);

  static const Color goldDark10 = Color(0xFF2D2416); // ذهبي داكن جداً
  static const Color goldDark20 = Color(0xFF4A3A23);

  // ── Secondary (Silver) Tints ──────────────
  static const Color silverLight10 = Color(0xFFF9FAFB);
  static const Color silverLight20 = Color(0xFFF3F4F6);
  static const Color silverLight30 = Color(0xFFE5E7EB);

  static const Color silverDark10 = Color(0xFF1F2937);
  static const Color silverDark20 = Color(0xFF374151);

  // ── Status Colors Tints ───────────────────
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color successDark = Color(0xFF064E3B);

  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFF7F1D1D);

  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFF78350F);

  // ── Shimmer & Loading ─────────────────────
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);
  static const Color shimmerBaseDark = Color(0xFF1F1F1F);
  static const Color shimmerHighlightDark = Color(0xFF2D2D2D);

  // ── Aliases for Backward Compatibility ────
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color textPrimary = lightText;
  static const Color textSecondary = lightTextSecondary;
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color border = lightBorder;
  static const Color divider = lightDivider;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Gradients ─────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldGradientStart, goldGradientEnd],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightSurface, lightSurfaceAlt],
  );

  // ── Helper Methods ────────────────────────
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
