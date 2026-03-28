import 'package:flutter/material.dart';

class Mot9Theme {
  static const bgColor = Color(0xFF141414);
  static const surfaceColor = Color(0xFF1F1F1F);
  static const cardColor = Color(0xFF2A2A2A);
  static const accentRed = Color(0xFFE50914);
  static const accentRedDark = Color(0xFFB20710);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAA);
  static const focusColor = Color(0xFFE50914);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgColor,
        colorScheme: const ColorScheme.dark(
          primary: accentRed,
          surface: surfaceColor,
          background: bgColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
          titleMedium: TextStyle(color: textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        ),
        focusColor: focusColor,
      );
}
