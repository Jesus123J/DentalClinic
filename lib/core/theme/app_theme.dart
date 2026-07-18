import 'package:flutter/material.dart';

/// Tema visual de la aplicacion (claro y oscuro).
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0E7490); // azul dental
  static const Color secondaryColor = Color(0xFF22D3EE);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.comfortable,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.comfortable,
      );
}
