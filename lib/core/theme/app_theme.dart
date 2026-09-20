import 'package:flutter/material.dart';

/// Paleta extraída de Figma (página «Tokens y variables»).
class AppColors {
  AppColors._();

  // Marca — valor exacto extraído del logo exportado (Figma nodo 5:21)
  static const brand = Color(0xFF8C3858);
  static const brandDark = Color(0xFF6E2C45);
  static const brandSoft = Color(0xFFF7F2F7);

  // Semánticos
  static const success = Color(0xFF219E69);
  static const successSoft = Color(0xFFACDBC7);
  static const danger = Color(0xFFD94C52);
  static const dangerSoft = Color(0xFFECA6A9);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFDE68A);
  static const info = Color(0xFF3B5BDB);
  static const infoSoft = Color(0xFFDCE3FB);

  // Neutros
  static const background = Color(0xFFFAF7F5);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEDEEF0);
  static const border = Color(0xFFE3E6EB);
  static const text = Color(0xFF1F1F24);
  static const text2 = Color(0xFF3B3A3E);
  static const muted = Color(0xFF707582);
  static const muted2 = Color(0xFFA6A9B1);
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

/// Radios (6 · 10 · 14 · pill).
class AppRadius {
  AppRadius._();

  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const pill = 999.0;
}

/// Escala tipográfica (Figma: Display 32 / H2 20 / Body 14 / Label 12).
class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const body = TextStyle(fontSize: 14, height: 1.5);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
}

/// Tema claro de FashionStore.
class AppTheme {
  AppTheme._();

  static final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
  ).copyWith(
    primary: AppColors.brand,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brandSoft,
    onPrimaryContainer: AppColors.brandDark,
    secondary: AppColors.brandDark,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: const Color(0xFF8F2F34),
    surface: AppColors.surface,
    onSurface: AppColors.text,
    outline: AppColors.border,
  );

  static ThemeData light() => ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkRipple.splashFactory,
  );
}
