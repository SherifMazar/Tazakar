import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF6C63FF);
  static const _surface = Color(0xFF1E1E2E);
  static const _background = Color(0xFF12121C);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(primary: _primary, surface: _surface),
    scaffoldBackgroundColor: _background,
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    useMaterial3: true,
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(primary: _primary),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
    useMaterial3: true,
  );
}
