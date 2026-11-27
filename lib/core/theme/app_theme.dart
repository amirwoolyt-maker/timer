// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'app_scenes.dart';

abstract final class AppColors {
  static const background = Color(0xFF0A0A0C);
  static const surface = Color(0xFF131825);
  static const surfaceRaised = Color(0xFF191F2E);
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF059669);
  static const text = Color(0xFFF3F4F6);
  static const muted = Color(0xFF969AA6);
  static const border = Color(0x17FFFFFF);
  static const amber = Color(0xFFF5B942);
  static const red = Color(0xFFFB7185);
  static const blue = Color(0xFF60A5FA);
  static const purple = Color(0xFFA78BFA);
}

ThemeData buildAppTheme({
  required bool dark,
  AppScene scene = AppScene.cosmic,
}) {
  final accent = dark ? scene.accent : scene.lightAccent;
  final background = scene.background(dark);
  final surface = scene.surface(dark);
  final raised = Color.alphaBlend(
    (dark ? Colors.white : accent).withValues(alpha: dark ? .035 : .025),
    surface,
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: surface,
    primary: accent,
    onPrimary: dark ? const Color(0xFF17131D) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
        .textTheme
        .apply(
          fontFamily: 'Vazirmatn',
          bodyColor: dark ? AppColors.text : const Color(0xFF17211D),
          displayColor: dark ? AppColors.text : const Color(0xFF17211D),
        ),
    dividerColor: dark ? AppColors.border : const Color(0xFFE5E7EB),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        foregroundColor: accent,
        textStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: accent.withValues(alpha: .45)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: scheme.onPrimary,
      elevation: 3,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: dark ? AppColors.border : const Color(0xFFE6EBE8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: raised,
      hintStyle: TextStyle(
        color: dark ? AppColors.muted : const Color(0xFF7B817E),
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: dark ? AppColors.border : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: accent),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? raised : const Color(0xFF1F2937),
      contentTextStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
