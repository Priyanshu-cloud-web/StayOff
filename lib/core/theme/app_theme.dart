import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── DARK COLORS ───────────────────────────────
class FGColors {
  FGColors._();
  static const purple       = Color(0xFF7C6FED);
  static const purpleLight  = Color(0xFFB8AEFF);
  static const purpleDark   = Color(0xFF4834D4);
  static const purpleGlow   = Color(0x1A7C6FED);
  static const purpleBorder = Color(0x407C6FED);
  static const teal         = Color(0xFF00C9A7);
  static const tealGlow     = Color(0x1A00C9A7);
  static const amber        = Color(0xFFFFB347);
  static const amberGlow    = Color(0x1AFFB347);
  static const red          = Color(0xFFFF6B6B);
  static const redGlow      = Color(0x1AFF6B6B);
  static const redBorder    = Color(0x40FF6B6B);
  static const bg           = Color(0xFF0C0C14);
  static const bg2          = Color(0xFF13131E);
  static const bg3          = Color(0xFF1A1A28);
  static const bg4          = Color(0xFF22223A);
  static const surface      = Color(0xFF2A2A40);
  static const textPrimary  = Color(0xFFEEEEFF);
  static const textSecond   = Color(0xFF9896C8);
  static const textThird    = Color(0xFF5D5B8A);
  static const textHint     = Color(0xFF3D3B5A);
  static const border       = Color(0x12FFFFFF);
  static const border2      = Color(0x1FFFFFFF);
  static const border3      = Color(0x33FFFFFF);
}

// ── LIGHT COLORS ──────────────────────────────
class FGColorsLight {
  FGColorsLight._();
  static const purple       = Color(0xFF6C5CE7);
  static const purpleLight  = Color(0xFF8B7CF6);
  static const purpleDark   = Color(0xFF4834D4);
  static const purpleGlow   = Color(0x146C5CE7);
  static const purpleBorder = Color(0x336C5CE7);
  static const teal         = Color(0xFF00A389);
  static const tealGlow     = Color(0x1400A389);
  static const amber        = Color(0xFFE09000);
  static const amberGlow    = Color(0x14E09000);
  static const red          = Color(0xFFE53E3E);
  static const redGlow      = Color(0x14E53E3E);
  static const redBorder    = Color(0x33E53E3E);
  static const bg           = Color(0xFFF5F5FA);
  static const bg2          = Color(0xFFFFFFFF);
  static const bg3          = Color(0xFFFFFFFF);
  static const bg4          = Color(0xFFF0EFF8);
  static const surface      = Color(0xFFE8E7F5);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textSecond   = Color(0xFF4A4870);
  static const textThird    = Color(0xFF9B99C0);
  static const textHint     = Color(0xFFBDBCDD);
  static const border       = Color(0x14000000);
  static const border2      = Color(0x1F000000);
  static const border3      = Color(0x33000000);
}

class FGRadius {
  static const sm   = BorderRadius.all(Radius.circular(10));
  static const md   = BorderRadius.all(Radius.circular(14));
  static const lg   = BorderRadius.all(Radius.circular(18));
  static const xl   = BorderRadius.all(Radius.circular(22));
  static const full = BorderRadius.all(Radius.circular(100));
}

class FGPad {
  static const pagePad = EdgeInsets.symmetric(horizontal: 18);
  static const card    = EdgeInsets.all(16);
  static const cardSm  = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
}

// ── THEMES ────────────────────────────────────
class FGTheme {
  FGTheme._();

  static ThemeData get dark  => _build(isDark: true);
  static ThemeData get light => _build(isDark: false);

  static ThemeData _build({required bool isDark}) {
    final bg   = isDark ? FGColors.bg   : FGColorsLight.bg;
    final bg2  = isDark ? FGColors.bg2  : FGColorsLight.bg2;
    final bg4  = isDark ? FGColors.bg4  : FGColorsLight.bg4;
    final p    = isDark ? FGColors.purple      : FGColorsLight.purple;
    final pL   = isDark ? FGColors.purpleLight : FGColorsLight.purpleLight;
    final teal = isDark ? FGColors.teal        : FGColorsLight.teal;
    final err  = isDark ? FGColors.red         : FGColorsLight.red;
    final tp   = isDark ? FGColors.textPrimary : FGColorsLight.textPrimary;
    final ts   = isDark ? FGColors.textSecond  : FGColorsLight.textSecond;
    final tt   = isDark ? FGColors.textThird   : FGColorsLight.textThird;
    final b2   = isDark ? FGColors.border2     : FGColorsLight.border2;

    final textTheme = TextTheme(
      displayLarge:  GoogleFonts.syne(fontSize: 48, fontWeight: FontWeight.w800, color: tp, height: 1.0),
      displayMedium: GoogleFonts.syne(fontSize: 36, fontWeight: FontWeight.w800, color: tp, height: 1.1),
      displaySmall:  GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w800, color: tp, height: 1.1),
      headlineLarge: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: tp),
      headlineMedium:GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: tp),
      headlineSmall: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w700, color: tp),
      titleLarge:    GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: tp),
      titleMedium:   GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: tp),
      titleSmall:    GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: tp),
      bodyLarge:     GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: tp, height: 1.6),
      bodyMedium:    GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w400, color: ts, height: 1.5),
      bodySmall:     GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: tt, height: 1.5),
      labelLarge:    GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: tp),
      labelMedium:   GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: tt),
      labelSmall:    GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: tt),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: bg,
      // Use .dark() / .light() named constructors — no 'background' needed
      colorScheme: isDark
          ? ColorScheme.dark(
              primary:   p,
              secondary: teal,
              surface:   bg2,
              error:     err,
              onPrimary:   Colors.white,
              onSecondary: Colors.white,
              onSurface:   tp,
              onError:     Colors.white,
            )
          : ColorScheme.light(
              primary:   p,
              secondary: teal,
              surface:   bg2,
              error:     err,
              onPrimary:   Colors.white,
              onSecondary: Colors.white,
              onSurface:   tp,
              onError:     Colors.white,
            ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: ts),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg2,
        indicatorColor: Colors.transparent,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return textTheme.labelSmall?.copyWith(color: pL);
          }
          return textTheme.labelSmall?.copyWith(color: tt);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: pL, size: 22);
          }
          return IconThemeData(color: tt, size: 22);
        }),
      ),
      dividerColor: isDark ? FGColors.border : FGColorsLight.border,
      cardColor: isDark ? FGColors.bg3 : FGColorsLight.bg3,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg4,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p),
        ),
        labelStyle: TextStyle(color: tt),
        hintStyle: TextStyle(color: tt),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? Colors.white : tt),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? teal : b2),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}