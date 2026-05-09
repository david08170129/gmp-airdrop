import 'package:flutter/material.dart';

import 'gmp_colors.dart';

class GmpTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GmpColors.blue,
      brightness: Brightness.light,
      primary: GmpColors.blue,
      surface: GmpColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GmpColors.background,
      fontFamily: 'Arial',
      textTheme: Typography.material2021().black.apply(
            bodyColor: GmpColors.text,
            displayColor: GmpColors.text,
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        toolbarHeight: 84,
        backgroundColor: GmpColors.surface,
        foregroundColor: GmpColors.text,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: GmpColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: GmpColors.line.withValues(alpha: 0.78)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 48),
          side: const BorderSide(color: GmpColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
