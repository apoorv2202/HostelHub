// lib/utils/app_theme.dart  -> the real one
import 'package:flutter/material.dart';

class AppTheme {
  // ── Core palette ────────────────────────────────────────
  static const Color backgroundBlack   = Color(0xFF0A0A0B); // base canvas
  static const Color surfaceDark        = Color(0xFF131316); // raised surface
  static const Color surfaceElevated    = Color(0xFF1C1C21);
  static const Color primaryOrange      = Color(0xFFFF6B35); // brand accent
  static const Color primaryOrangeSoft  = Color(0xFFFF8A5C);
  static const Color accentGlow         = Color(0x33FF6B35);

  // ── Text (Brightened for maximum dark-mode visibility) ──
  static const Color textWhite = Color(0xFFFFFFFF); // Pure high-contrast white
  static const Color textGrey   = Color(0xFFE4E4E7); // Lighter gray (Zinc 200) for excellent readability
  static const Color textFaint  = Color(0xFFA1A1AA); // Brighter faint gray (Zinc 400) so it doesn't blend into black

  // ── Status colors (used by admin_dashboard.dart already) ─
  static const Color statusPending   = Color(0xFFFFB020);
  static const Color statusAccepted  = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF22C55E);
  static const Color statusRejected  = Color(0xFFEF4444);

  // ── Backward compatibility aliases for existing screens ──
  static const Color bg = backgroundBlack;
  static const Color primary = primaryOrange;
  static const Color primaryLight = Color(0x26FF6B35); // Lighter translucent orange for container highlights (15% opacity)
  static const Color secondary = Color(0xFFFF8A5C); // Vibrant primary orange soft as secondary
  static const Color secondaryLight = Color(0x26FF8A5C);
  static const Color success = statusCompleted;
  static const Color successLight = Color(0x2622C55E); // 15% opacity success green
  static const Color warning = statusPending;
  static const Color warningLight = Color(0x26FFB020); // 15% opacity warning yellow
  static const Color error = statusRejected;
  static const Color errorLight = Color(0x26EF4444); // 15% opacity error red

  // Aliased to high-contrast dark-mode colors
  static const Color textDark = textWhite;     // Previously dark text, now pure white for dark canvas
  static const Color textMedium = textGrey;    // Previously medium gray, now bright zinc gray
  static const Color textLight = textFaint;    // Previously light gray, now readable zinc gray

  static const Color cardBorder = Color(0xFF2E2E33); // High-contrast border outline for cards
  static const Color divider = Color(0xFF2E2E33);     // Subtle but visible divider line
  static const Color cardBlack = surfaceDark;
  static const Color dividerBlack = Color(0xFF2E2E33);

  // ── Glass tokens ────────────────────────────────────────
  static const double glassBlur     = 18.0;
  static const double glassOpacity  = 0.06;
  static const double radiusSm = 14, radiusMd = 22, radiusLg = 30;
  static Border glassBorder = Border.all(color: Colors.white.withOpacity(0.08));

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primaryOrange, Color(0xFFFF4D2E)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── ThemeData ───────────────────────────────────────────
  static ThemeData get lightTheme => darkTheme; // alias so main.dart keeps working
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundBlack,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: primaryOrange,
          secondary: primaryOrangeSoft,
          surface: surfaceDark,
          background: backgroundBlack,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textWhite, fontSize: 20, fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceDark,
          labelStyle: const TextStyle(color: textGrey, fontSize: 14),
          hintStyle: const TextStyle(color: textFaint, fontSize: 14),
          prefixIconColor: textGrey,
          suffixIconColor: textGrey,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: const BorderSide(color: cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: const BorderSide(color: cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: const BorderSide(color: primaryOrange, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            borderSide: const BorderSide(color: statusRejected),
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
        ),
      );
}
