import 'package:flutter/material.dart';

class Mot9Theme {
  static const bgColor = Color(0xFF0F0F0F);
  static const surfaceColor = Color(0xFF1A1A1A);
  static const cardColor = Color(0xFF222222);
  static const accentRed = Color(0xFFE50914);
  static const accentRedDark = Color(0xFFB20710);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF999999);

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgColor,
    colorScheme: const ColorScheme.dark(primary: accentRed, surface: surfaceColor),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
    focusColor: accentRed,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 12),
    ),
  );
}
