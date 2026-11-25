import 'package:flutter/material.dart';

class AppTheme {
  static const Color verde = Color(0xFF1B7A3D);
  static const Color verdeClaro = Color(0xFFE8F5ED);
  static const Color naranja = Color(0xFFF59E0B);
  static const Color fondo = Color(0xFFF6F7F6);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: fondo,
    primaryColor: verde,
    colorScheme: const ColorScheme.light(primary: verde),
    appBarTheme: const AppBarTheme(
      backgroundColor: verde,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: verde, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

