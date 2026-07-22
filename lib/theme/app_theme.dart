import 'package:flutter/material.dart';

/// News Insights' own visual identity — deliberately distinct from
/// YsWords' blue theme, since this is a standalone app, not a reskin.
/// A warm amber/gold seed reads as "editorial" (masthead, ink-on-
/// paper) rather than "corporate blue"; Material 3's tonal system
/// derives the full light/dark neutral palette (including the
/// charcoal-toned dark-mode surfaces) from this one seed.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFFB8860B); // warm amber / dark goldenrod

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
      // No `platform:` override here — this app is bilingual (EN/中文)
      // and Typography's iOS/"englishLike" geometry (tight letter-
      // spacing tuned for Latin scripts) mis-measured some CJK glyph
      // combinations tightly enough to clip chip labels (e.g. "世界"
      // rendered as just "世"). The platform-default geometry picks
      // the CJK-safe "dense" set on Android/other non-Apple targets.
      textTheme: Typography.material2021().black.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
