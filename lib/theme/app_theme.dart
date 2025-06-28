import 'package:flutter/material.dart';

class AppTheme {
  static const Color fallbackSeedColor = Colors.teal;

  static ThemeData light([Color? seedColor]) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor ?? fallbackSeedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  static ThemeData dark([Color? seedColor]) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor ?? fallbackSeedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}

/// Returns a color based on the balance value: green if > 0, red if < 0, grey if 0.
Color byBalance(double v) {
  if (v > 0) return Colors.green;
  if (v < 0) return Colors.red;
  return Colors.grey;
}
