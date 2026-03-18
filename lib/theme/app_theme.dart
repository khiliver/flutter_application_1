import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0066CC);
  static const Color accentColor = Color(0xFF00CC99);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;

  static final TextTheme textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
    );
  }
}
