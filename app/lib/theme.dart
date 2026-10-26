import 'package:flutter/material.dart';

/// Same tokens as agent/public/theme.css, so the phone app, browser deck and PC editor look like one product.
abstract final class Tokens {
  static const bg = Color(0xFF0F1012);
  static const panel = Color(0xFF16171A);
  static const raised = Color(0xFF1E2024);
  static const key = Color(0xFF26282D);
  static const border = Color(0xFF2B2E33);
  static const text = Color(0xFFE8E9EB);
  static const muted = Color(0xFF9A9EA6);
  static const accent = Color(0xFFF5A524);
  static const ok = Color(0xFF3CCF91);
  static const danger = Color(0xFFEF5B5B);
  static const rKey = 12.0;
  static const rPanel = 8.0;
}

const palette = ['#26282d', '#3a3f47', '#2563eb', '#0d9488', '#16a34a', '#ca8a04', '#ea580c', '#dc2626', '#db2777', '#7c3aed'];

Color hexColor(String? hex) => Color(int.parse((hex ?? palette.first).substring(1), radix: 16) | 0xFF000000);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Tokens.accent, brightness: Brightness.dark).copyWith(
    primary: Tokens.accent,
    onPrimary: const Color(0xFF1A1204),
    surface: Tokens.bg,
    onSurface: Tokens.text,
    surfaceContainerHighest: Tokens.raised,
    outline: Tokens.border,
    error: Tokens.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Tokens.bg,
    appBarTheme: const AppBarTheme(backgroundColor: Tokens.bg, surfaceTintColor: Colors.transparent, elevation: 0),
    chipTheme: ChipThemeData(
      backgroundColor: Tokens.bg,
      selectedColor: Tokens.text,
      side: const BorderSide(color: Tokens.border),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(color: Tokens.text),
      secondaryLabelStyle: const TextStyle(color: Tokens.bg, fontWeight: FontWeight.w600),
      checkmarkColor: Tokens.bg,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tokens.raised,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.rPanel), borderSide: const BorderSide(color: Tokens.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Tokens.rPanel), borderSide: const BorderSide(color: Tokens.border)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: Tokens.raised, contentTextStyle: TextStyle(color: Tokens.text)),
  );
}
