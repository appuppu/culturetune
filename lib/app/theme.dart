import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/tokens.dart';

/// 選択中のCTPaletteからThemeDataを構築する
ThemeData buildThemeData(CTPalette palette) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: palette.brightness,
      primary: palette.primary,
      surface: palette.surface,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: palette.bgBase,
    textTheme: GoogleFonts.mPlusRounded1cTextTheme(
      base.textTheme,
    ).apply(bodyColor: palette.textMain, displayColor: palette.textMain),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: palette.textMain,
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CTRadius.card),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.mPlusRounded1c(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.textMain,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CTRadius.button),
      ),
    ),
  );
}
