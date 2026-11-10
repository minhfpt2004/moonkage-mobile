import 'package:flutter/material.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';

abstract final class MoonkageTheme {
  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: MoonkageColors.royalRed,
      onPrimary: Colors.white,
      primaryContainer: MoonkageColors.paleGold,
      onPrimaryContainer: MoonkageColors.imperialRed,
      secondary: MoonkageColors.jade,
      onSecondary: Colors.white,
      secondaryContainer: MoonkageColors.paleJade,
      onSecondaryContainer: MoonkageColors.jade,
      tertiary: MoonkageColors.gold,
      onTertiary: MoonkageColors.ink,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: MoonkageColors.surface,
      onSurface: MoonkageColors.ink,
      outline: MoonkageColors.outline,
      shadow: Color(0x33000000),
      scrim: Color(0x66000000),
      inverseSurface: MoonkageColors.ink,
      onInverseSurface: MoonkageColors.surface,
      inversePrimary: MoonkageColors.paleGold,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MoonkageColors.surface,
      fontFamilyFallback: const ['Be Vietnam Pro', 'Roboto', 'sans-serif'],
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: MoonkageColors.imperialRed,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: MoonkageColors.imperialRed,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: MoonkageColors.imperialRed,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: MoonkageColors.surface,
        foregroundColor: MoonkageColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: MoonkageColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: const BorderSide(color: MoonkageColors.royalRed),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: MoonkageColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: MoonkageColors.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: MoonkageColors.paleGold,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? MoonkageColors.imperialRed
                : MoonkageColors.mutedInk,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: MoonkageColors.outline),
    );
  }

  const MoonkageTheme._();
}
