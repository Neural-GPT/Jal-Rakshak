import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Dark theme surfaces ───────────────────────────────────────────────────
  static const bgDark       = Color(0xFF060810);
  static const surfaceDark  = Color(0xFF0E1117);
  static const cardDark     = Color(0xFF131720);
  static const borderDark   = Color(0xFF1E2535);

  // ── Light theme surfaces ──────────────────────────────────────────────────
  static const bgLight      = Color(0xFFF2F5FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardLight    = Color(0xFFFFFFFF);
  static const borderLight  = Color(0xFFDDE3F0);

  // ── Accent (shared) ───────────────────────────────────────────────────────
  static const cyan         = Color(0xFF00E5CC);
  static const cyanDim      = Color(0xFF00B8A3);
  static const cyanDark     = Color(0xFF007A6E);  // for light theme text
  static const cyanGlow     = Color(0x3300E5CC);
  static const blue         = Color(0xFF3D8EFF);
  static const blueDark     = Color(0xFF1A5FCC);  // for light theme
  static const red          = Color(0xFFFF4D6A);
  static const amber        = Color(0xFFFFB830);

  // ── Status ────────────────────────────────────────────────────────────────
  static const filling      = Color(0xFF00E5CC);
  static const filled       = Color(0xFF3D8EFF);
  static const inactive     = Color(0xFF3A4155);
}

class AppTheme {
  // ── DARK (default) ────────────────────────────────────────────────────────
  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary:          AppColors.cyan,
      secondary:        AppColors.blue,
      surface:          AppColors.surfaceDark,
      error:            AppColors.red,
      onPrimary:        Colors.black,
      onSurface:        Color(0xFFCDD6F4),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor:    const Color(0xFFCDD6F4),
      displayColor: Colors.white,
    ),
    cardColor:    AppColors.cardDark,
    dividerColor: AppColors.borderDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgDark,
      elevation: 0,
      titleTextStyle: TextStyle(
        color:      Colors.white,
        fontSize:   18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Colors.white70),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor:  AppColors.bgDark,
      indicatorColor:   AppColors.cyan.withOpacity(0.15),
      labelTextStyle:   WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      selected ? AppColors.cyan : Colors.white38,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.cyan
              : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.cyan.withOpacity(0.35)
              : Colors.grey.withOpacity(0.2)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor:   AppColors.cyan,
      inactiveTrackColor: Color(0xFF1E2535),
      thumbColor:         AppColors.cyan,
    ),
    chipTheme: ChipThemeData(
      backgroundColor:  AppColors.cardDark,
      selectedColor:    AppColors.cyan.withOpacity(0.15),
      labelStyle:       const TextStyle(fontSize: 11),
      side: const BorderSide(color: AppColors.borderDark),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:           true,
      fillColor:        AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.cyan),
      ),
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
    ),
    useMaterial3: true,
  );

  // ── LIGHT (white) ─────────────────────────────────────────────────────────
  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary:          AppColors.cyanDark,
      secondary:        AppColors.blueDark,
      surface:          AppColors.surfaceLight,
      error:            AppColors.red,
      onPrimary:        Colors.white,
      onSurface:        Color(0xFF1A1F36),
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor:    const Color(0xFF2D3748),
      displayColor: const Color(0xFF1A1F36),
    ),
    cardColor:    AppColors.cardLight,
    dividerColor: AppColors.borderLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgLight,
      elevation:       0,
      titleTextStyle: TextStyle(
        color:      Color(0xFF1A1F36),
        fontSize:   18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFF1A1F36)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      indicatorColor:  AppColors.cyanDark.withOpacity(0.12),
      labelTextStyle:  WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      selected
              ? AppColors.cyanDark
              : const Color(0xFF9CA3AF),
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.cyanDark
              : Colors.grey.shade400),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.cyanDark.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor:   AppColors.cyanDark,
      inactiveTrackColor: AppColors.borderLight,
      thumbColor:         AppColors.cyanDark,
    ),
    chipTheme: ChipThemeData(
      backgroundColor:  AppColors.cardLight,
      selectedColor:    AppColors.cyanDark.withOpacity(0.1),
      labelStyle:       const TextStyle(fontSize: 11),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled:       true,
      fillColor:    AppColors.cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:   const BorderSide(color: AppColors.cyanDark),
      ),
      labelStyle: const TextStyle(
          color: Color(0xFF9CA3AF), fontSize: 12),
    ),
    shadowColor: Colors.black12,
    useMaterial3: true,
  );
}