import 'package:flutter/material.dart';

// App colors are kept here so the whole app can be recolored in one place.
class PwdColors {
  static const orange = Color(0xFFE97845);
  static const green = Color(0xFF31836D);
  static const navy = Color(0xFF173C4A);
  static const ink = Color(0xFF15242B);
  static const muted = Color(0xFF60717A);
  static const outline = Color(0xFFD7E0E3);
  static const amber = Color(0xFFA66311);
  static const statusGreen = Color(0xFF21805A);
  static const darkOrange = Color(0xFFB94B22);
  static const red = Color(0xFFB44A4A);
  static const logout = Color(0xFFB44A4A);
  static const surface = Colors.white;
  static const background = Color(0xFFF5F7F8);
  static const softOrange = Color(0xFFFFF1E8);
  static const softGreen = Color(0xFFEAF4F0);
  static const mapBackground = Color(0xFFE8EEF0);
  static const mapArtwork = Color(0xFFB0C2C7);
  static const success = Color(0xFF21805A);
  static const locationPin = Color(0xFFD9534F);

  // A soft brand tint used on the opening screen.
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF0E7), Colors.white, Color(0xFFEEF5F1)],
    stops: [0, 0.55, 1],
  );
}

// Shared measurements. Adjusting these updates commonly reused components.
class PwdSizes {
  static const buttonHeight = 50.0;
  static const inputCornerRadius = 12.0;
  static const cardCornerRadius = 18.0;
  static const appBarTitleSize = 19.0;
  static const statusPillFontSize = 12.0;
  static const statusPillRadius = 20.0;
  static const contentMaxWidth = 1120.0;
}

class PwdTheme {
  static ThemeData get data {
    final colors = ColorScheme.fromSeed(
      seedColor: PwdColors.orange,
      brightness: Brightness.light,
      primary: PwdColors.orange,
      secondary: PwdColors.green,
      surface: PwdColors.surface,
      error: PwdColors.red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: PwdColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: PwdColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PwdColors.ink,
        titleTextStyle: TextStyle(
          color: PwdColors.ink,
          fontSize: PwdSizes.appBarTitleSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: PwdColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PwdSizes.cardCornerRadius),
          side: const BorderSide(color: PwdColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PwdColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: PwdColors.muted),
        labelStyle: const TextStyle(color: PwdColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PwdSizes.inputCornerRadius),
          borderSide: const BorderSide(color: PwdColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PwdSizes.inputCornerRadius),
          borderSide: const BorderSide(color: PwdColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PwdSizes.inputCornerRadius),
          borderSide: const BorderSide(
            color: PwdColors.orange,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PwdColors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PwdSizes.inputCornerRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PwdColors.navy,
          side: const BorderSide(color: PwdColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PwdSizes.inputCornerRadius),
          ),
        ),
      ),
    );
  }
}