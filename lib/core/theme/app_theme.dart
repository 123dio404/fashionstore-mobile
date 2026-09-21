import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tipografía del prototipo Figma Make (design/figma-make/src/ui.tsx).
///
/// Acento terracota #E05A47 (marca), fondo #F8F9FA, texto #111827,
/// tipografía DM Serif Display (títulos) + Inter (cuerpo).
/// Reemplaza la paleta anterior basada en el vino #8C3858.
class AppColors {
  AppColors._();

  // Marca / acento (terracota).
  static const accent = Color(0xFFE05A47);
  static const accentDark = Color(0xFFC24A38);
  static const accentSoft = Color(0xFFFCEAE6);

  // Neutros.
  static const dark = Color(0xFF111827);
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6B7280);
  static const mutedLight = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);

  // Semánticos.
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const danger = Color(0xFFE05A47); // el prototipo usa terracota como rojo/error
  static const dangerBg = Color(0xFFFEF2F2);
  static const info = Color(0xFF2563EB);
  static const infoBg = Color(0xFFDBEAFE);

  // Alias de compatibilidad con el código existente.
  static const brand = accent;
  static const brandDark = accentDark;
  static const brandSoft = accentSoft;
  static const text = dark;
  static const text2 = dark;
  static const surface2 = borderLight;
  static const muted2 = mutedLight;
  static const successSoft = successBg;
  static const dangerSoft = dangerBg;
  static const warningSoft = warningBg;
  static const infoSoft = infoBg;
}

/// Escala de espaciado (4 · 8 · 12 · 16 · 24 · 32).
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radios (8 · 12 · 16 · 20 · pill).
class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const pill = 999.0;
}

/// Escala tipográfica: DM Serif Display (display) + Inter (body).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display =>
      GoogleFonts.dmSerifDisplay(fontSize: 32, height: 1.15);
  static TextStyle get h2 =>
      GoogleFonts.dmSerifDisplay(fontSize: 20, height: 1.3);
  static TextStyle get body => GoogleFonts.inter(fontSize: 14, height: 1.5);
  static TextStyle get label =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);

  /// Título serif a medida (Home usa 24, secciones 18, onboarding 28).
  static TextStyle displaySize(double size, {Color color = AppColors.dark}) =>
      GoogleFonts.dmSerifDisplay(fontSize: size, color: color, height: 1.15);

  /// Texto de cuerpo Inter con peso opcional.
  static TextStyle bodySize(
    double size, {
    Color color = AppColors.dark,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );
}

/// Tema claro de FashionStore (prototipo Figma Make).
class AppTheme {
  AppTheme._();

  static final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.accentDark,
    secondary: AppColors.accentDark,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerBg,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.dark,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.border,
  );

  static ThemeData light() => ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.dark,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: TextTheme(
      headlineLarge: AppTextStyles.display,
      headlineMedium: AppTextStyles.displaySize(24),
      titleLarge: AppTextStyles.displaySize(20),
      titleMedium: AppTextStyles.displaySize(18),
      bodyMedium: AppTextStyles.body,
      labelLarge: AppTextStyles.bodySize(14, weight: FontWeight.w600),
    ),
  );
}
