import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2ECC87);
  static const primaryDark = Color(0xFF1DBF85);
  static const primaryLight = Color(0xFFE8F8F0);
  static const orange = Color(0xFFFF8247);
  static const orangeSoft = Color(0xFFFFF0E8);
  static const femaleName = Color(0xFFE93344);
  static const maleName = Color(0xFF2196F3);
  static const textPrimary = Color(0xFF2C2C2C);
  static const textSecondary = Color(0xFF999999);
  static const pageBg = Color(0xFFF5F7F6);
  static const paperBg = Color(0xFFF7F4EF);
  static const card = Colors.white;
  static const divider = Color(0xFFEEEEEE);
  static const danger = Color(0xFFE53935);
  static const navInactive = Color(0xFF666666);
  static const ink = Color(0xFF333333);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
