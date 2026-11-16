import 'package:flutter/material.dart';

const brand = Color(0xFF8764C1);
const ink = Color(0xFF3F2A67);
const action = Color(0xFF624092);
const canvas = Color(0xFFF9F8FC);
const muted = Color(0xFF665B74);
const line = Color(0xFFE1D9EB);
const danger = Color(0xFFAD253A);
const success = Color(0xFF246A47);

ThemeData gestoPagoTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: brand).copyWith(
    primary: action,
    onPrimary: Colors.white,
    surface: Colors.white,
    error: danger,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: canvas,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: action, width: 2),
      ),
      labelStyle: const TextStyle(color: muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFEDE4F7),
    ),
  );
}
