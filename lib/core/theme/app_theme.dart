import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Muted Professional Palette
  // Muted Professional Palette
  static const Color _primaryGreen = Color(0xFF15803D); // Primary Green
  static const Color _softGreen = Color(0xFF4ADE80); // Secondary Accent
  static const Color _mutedRed = Color(0xFFB91C1C); // Error
  static const Color _neutralGray = Color(0xFFF1F5F9); // Background
  static const Color _surface = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: _primaryGreen,
        onPrimary: Colors.white,
        secondary: _softGreen,
        onSecondary: Colors.black87,
        error: _mutedRed,
        onError: Colors.white,
        surface: _surface,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: _neutralGray,
      textTheme: GoogleFonts.interTextTheme(),

      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _primaryGreen,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }
}
