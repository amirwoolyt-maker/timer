// ignore: deprecated_member_use
import 'package:flutter/material.dart';

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

ThemeData buildAppTheme({required bool dark}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: dark ? Brightness.dark : Brightness.light,
    surface: dark ? AppColors.surface : const Color(0xFFFFFFFF),
    primary: AppColors.emerald,
    onPrimary: const Color(0xFF041B12),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Vazirmatn',
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? AppColors.background
        : const Color(0xFFF5F7F6),
    textTheme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light)
        .textTheme
        .apply(
          fontFamily: 'Vazirmatn',
          bodyColor: dark ? AppColors.text : const Color(0xFF17211D),
          displayColor: dark ? AppColors.text : const Color(0xFF17211D),
        ),
    dividerColor: dark ? AppColors.border : const Color(0xFFE5E7EB),
    cardTheme: CardThemeData(
      color: dark ? AppColors.surface : Colors.white,
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
      fillColor: dark ? AppColors.surfaceRaised : const Color(0xFFF1F4F2),
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
        borderSide: const BorderSide(color: AppColors.emerald),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? AppColors.surfaceRaised : const Color(0xFF1F2937),
      contentTextStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
