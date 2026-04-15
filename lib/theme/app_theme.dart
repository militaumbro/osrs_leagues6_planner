import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryRed = Color(0xFFB71C1C);
  static const _accentOrange = Color(0xFFFF6D00);
  static const _darkBg = Color(0xFF121212);
  static const _surfaceDark = Color(0xFF1E1E1E);
  static const _cardDark = Color(0xFF2A2A2A);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _darkBg,
        colorScheme: const ColorScheme.dark(
          primary: _primaryRed,
          secondary: _accentOrange,
          surface: _surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _surfaceDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: _cardDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _accentOrange;
            }
            return Colors.grey[700];
          }),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: _accentOrange,
          linearTrackColor: Color(0xFF3A3A3A),
        ),
      );

  static Color difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.amber;
      case 'hard':
        return Colors.orange;
      case 'elite':
        return Colors.deepPurple;
      case 'master':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
