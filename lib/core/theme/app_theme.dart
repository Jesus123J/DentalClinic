import 'package:flutter/material.dart';

/// Transicion nula: la pagina nueva aparece al instante, sin animacion.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

/// Tema visual de la aplicacion (claro y oscuro).
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF0E7490); // azul dental
  static const Color secondaryColor = Color(0xFF22D3EE);

  static const PageTransitionsTheme _noTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _NoTransitionsBuilder(),
      TargetPlatform.iOS: _NoTransitionsBuilder(),
      TargetPlatform.windows: _NoTransitionsBuilder(),
      TargetPlatform.macOS: _NoTransitionsBuilder(),
      TargetPlatform.linux: _NoTransitionsBuilder(),
      TargetPlatform.fuchsia: _NoTransitionsBuilder(),
    },
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.comfortable,
        pageTransitionsTheme: _noTransitions,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.comfortable,
        pageTransitionsTheme: _noTransitions,
      );
}
