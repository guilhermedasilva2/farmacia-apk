import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF00796B), // Colors.teal[700] (Original App "Primary")
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB2DFDB), // Lighter container for contrast
    onPrimaryContainer: Color(0xFF004D40),
    secondary: Color(0xFF00ACC1), // Colors.cyan[600] (Original App "Secondary" for gradient)
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB2EBF2),
    onSecondaryContainer: Color(0xFF006064),
    tertiary: Color(0xFF00ACC1),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB2EBF2),
    onTertiaryContainer: Color(0xFF006064),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
    onError: Color(0xFFFFFFFF),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF5F5F5), // Colors.grey[100]
    onSurface: Color(0xFF00695C), // Colors.teal[800] - text color
    onSurfaceVariant: Color(0xFF616161), // Colors.grey[700]
    outline: Color(0xFF757575),
    onInverseSurface: Color(0xFFF4F1FA),
    inverseSurface: Color(0xFF00695C),
    inversePrimary: Color(0xFF80CBC4),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF00796B),
    outlineVariant: Color(0xFFCAC4D0),
    scrim: Color(0xFF000000),
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF80CBC4), // Colors.teal[200]
    onPrimary: Color(0xFF00332C),
    primaryContainer: Color(0xFF004D40), // Colors.teal[900]
    onPrimaryContainer: Color(0xFFB2DFDB),
    secondary: Color(0xFF4DD0E1), // Colors.cyan[300]
    onSecondary: Color(0xFF00363D),
    secondaryContainer: Color(0xFF006064),
    onSecondaryContainer: Color(0xFFB2EBF2),
    tertiary: Color(0xFF4DD0E1),
    onTertiary: Color(0xFF00363D),
    tertiaryContainer: Color(0xFF004D40),
    onTertiaryContainer: Color(0xFFB2DFDB),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),
    onError: Color(0xFF690005),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121212),
    onSurface: Color(0xFFE0F2F1), // Very light teal/white
    onSurfaceVariant: Color(0xFFBDBDBD),
    outline: Color(0xFF938F99),
    onInverseSurface: Color(0xFF00332C),
    inverseSurface: Color(0xFFE0F2F1),
    inversePrimary: Color(0xFF00695C),
    shadow: Color(0xFF000000),
    surfaceTint: Color(0xFF80CBC4),
    outlineVariant: Color(0xFF49454F),
    scrim: Color(0xFF000000),
  );

  static InputDecorationTheme _lightInputDecorationTheme() {
    return InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Color(0xFF004D40), width: 2), // dark teal
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF004D40)), // dark teal
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F), // error red
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(
          color: const Color(0xFF009688).withValues(alpha: 0.5), // teal
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F), // error red
          width: 2,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      inputDecorationTheme: _lightInputDecorationTheme(),
      scaffoldBackgroundColor: _lightColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.primaryContainer,
        foregroundColor: _lightColorScheme.onPrimaryContainer,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.primaryContainer,
        foregroundColor: _lightColorScheme.onPrimaryContainer,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: _darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.primaryContainer,
        foregroundColor: _darkColorScheme.onPrimaryContainer,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.primaryContainer,
        foregroundColor: _darkColorScheme.onPrimaryContainer,
      ),
      // Adicionando um input decoration básico para o dark mode também, para consistência
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: _darkColorScheme.surface,
      ),
    );
  }
}
