import 'package:flutter/material.dart';

const Color bgColor = Color(0xFF0D1B2A);
const Color surfaceColor = Color(0xFF112236);
const Color accentTeal = Color(0xFF0E6E8A);
const Color primaryText = Color(0xFFFFFFFF);
const Color secondaryText = Color(0xFFA0B4C0);
const Color warningColor = Color(0xFFE8A020);
const Color criticalColor = Color(0xFFC0392B);
const Color safeColor = Color(0xFF1A8A4A);

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bgColor,
  primaryColor: accentTeal,
  cardColor: surfaceColor,
  colorScheme: const ColorScheme.dark(
    primary: accentTeal,
    secondary: warningColor,
    surface: surfaceColor,
    error: criticalColor,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: primaryText),
    bodyMedium: TextStyle(color: primaryText),
    bodySmall: TextStyle(color: secondaryText),
    titleLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: surfaceColor,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryText),
    titleTextStyle: TextStyle(color: primaryText, fontSize: 20, fontWeight: FontWeight.bold),
  ),
);
