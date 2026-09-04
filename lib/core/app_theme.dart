import 'package:flutter/material.dart';

class AppTheme {
  static const accent = Color(0xFF007AFF);
  static const page = Color(0xFFF2F2F7);
  static const sidebar = Color(0xFF1C1C1E);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansSinhala',
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        scaffoldBackgroundColor: page,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: Color(0xFFE5E5EA)),
          ),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'NotoSansSinhala',
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ),
      );
}
