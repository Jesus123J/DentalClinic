import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Identidad visual de ProDentist: dorado + plata sobre fondos claros,
/// tarjetas planas redondeadas y tipografia Poppins (estilo web app).
class AppTheme {
  AppTheme._();

  // Colores de marca (del logo ProDentist).
  static const Color gold = Color(0xFFD9A521);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color silver = Color(0xFF9AA5B1);
  static const Color charcoal = Color(0xFF1F242D); // sidebar oscuro
  static const Color charcoalLight = Color(0xFF2B313C);
  static const Color background = Color(0xFFF5F6F8);

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

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: brightness,
      primary: isDark ? const Color(0xFFE8B637) : goldDark,
      secondary: silver,
    );
    final baseText = isDark
        ? GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: baseText,
      scaffoldBackgroundColor: isDark ? const Color(0xFF15181E) : background,
      visualDensity: VisualDensity.comfortable,
      pageTransitionsTheme: _noTransitions,
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? charcoalLight : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE5E8EC),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? charcoal : const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : const Color(0xFFE5E8EC),
      ),
    );
  }

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);
}
