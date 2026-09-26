import 'package:flutter/material.dart';
class AppTheme {
  AppTheme._(); 

  static ThemeData get light => _build(
        const ColorScheme.light(
          surface: Color(0xFFFFFFFF), 
          onSurface: Color(0xFF000000), 
          onSurfaceVariant: Color(0xFF757575), 
          surfaceContainer: Color(0xFFF5F5F5), 
          surfaceContainerHighest: Color(0xFFEDEDED), 
          outlineVariant: Color(0xFFD1D1D6), 
          primary: Color(0xFF000000),
          onPrimary: Color(0xFFFFFFFF),
        ),
      );

  static ThemeData get dark => _build(
        const ColorScheme.dark(
          surface: Color(0xFF000000),
          onSurface: Color(0xFFFFFFFF),
          onSurfaceVariant: Color(0xFF8E8E93),
          surfaceContainer: Color(0xFF121212),
          surfaceContainerHighest: Color(0xFF1C1C1E),
          outlineVariant: Color(0xFF3A3A3C),
          primary: Color(0xFFFFFFFF),
          onPrimary: Color(0xFF000000),
        ),
      );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'WorkSans',
      fontFamilyFallback: const ['NotoSansArabic'],
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700), // "History", greeting
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25), // prompts
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4), // entry text
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.35), // previews
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.2), // dates
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}