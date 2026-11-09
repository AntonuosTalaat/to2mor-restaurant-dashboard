import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _arabic = 'Cairo';
  static const String _english = 'Poppins';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.3,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _arabic,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _arabic,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _arabic,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _arabic,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _arabic,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _arabic,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _arabic,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.3,
  );

  static const TextStyle titleEn = TextStyle(
    fontFamily: _english,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyEn = TextStyle(
    fontFamily: _english,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
}
 
