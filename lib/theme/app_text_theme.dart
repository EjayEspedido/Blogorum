import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final List<BoxShadow> boxShadows;

  const AppThemeExtension({required this.boxShadows});

  @override
  AppThemeExtension copyWith({List<BoxShadow>? boxShadows}) {
    return AppThemeExtension(boxShadows: boxShadows ?? this.boxShadows);
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }

    return AppThemeExtension(
      boxShadows: t < 0.5 ? boxShadows : other.boxShadows,
    );
  }
}

class AppTextTheme {
  static const Color orangeAccent = Color(0xFFF06D22);
  static const Color tealAccent = Color(0xFF1C9DB6);

  static const List<BoxShadow> lightBoxShadows = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> darkBoxShadows = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Light Mode
  static TextTheme lightTextTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 42,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: orangeAccent,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: tealAccent,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: tealAccent,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: orangeAccent,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 18,
      height: 1.8,
      color: Color(0xFF2D2B29),
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 16,
      height: 1.7,
      color: Color(0xFF6F6B65),
    ),
    labelLarge: TextStyle(
      fontFamily: 'Arial',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
      color: tealAccent,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Arial',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: orangeAccent,
    ),
  );

  // Dark Mode
  static TextTheme darkTextTheme = const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 42,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: orangeAccent,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: tealAccent,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: tealAccent,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: orangeAccent,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 18,
      height: 1.8,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 16,
      height: 1.7,
      color: Colors.white70,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Arial',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
      color: tealAccent,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Arial',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: orangeAccent,
    ),
  );
}