import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseText = ThemeData.light().textTheme;
    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: LightColors.textPrimary,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: LightColors.textPrimary,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: LightColors.textPrimary,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: LightColors.textPrimary,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 16,
        color: LightColors.textPrimary,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 14,
        color: LightColors.textSecondary,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    const radius12 = BorderRadius.all(Radius.circular(12));
    const radius16 = BorderRadius.all(Radius.circular(16));

    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: LightColors.primary,
        onPrimary: Colors.white,
        secondary: LightColors.secondary,
        onSecondary: Colors.white,
        error: LightColors.error,
        onError: Colors.white,
        surface: LightColors.surface,
        onSurface: LightColors.textPrimary,
      ),
      scaffoldBackgroundColor: LightColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius16),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: LightColors.primary, width: 1.4),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    final baseText = ThemeData.dark().textTheme;
    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        color: DarkColors.textPrimary,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 24,
        color: DarkColors.textPrimary,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: DarkColors.textPrimary,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: DarkColors.textPrimary,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 16,
        color: DarkColors.textPrimary,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 14,
        color: DarkColors.textSecondary,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    const radius12 = BorderRadius.all(Radius.circular(12));
    const radius16 = BorderRadius.all(Radius.circular(16));

    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: DarkColors.primary,
        onPrimary: Color(0xFF08152F),
        secondary: DarkColors.secondary,
        onSecondary: Color(0xFF05281F),
        error: DarkColors.error,
        onError: Color(0xFF2A0A0A),
        surface: DarkColors.surface,
        onSurface: DarkColors.textPrimary,
      ),
      scaffoldBackgroundColor: DarkColors.background,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius16),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: DarkColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: Color(0xFF31394A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: Color(0xFF31394A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: DarkColors.primary, width: 1.4),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      useMaterial3: true,
    );
  }
}
