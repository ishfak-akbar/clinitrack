import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryTeal,
      primary: AppColors.primaryTeal,
      secondary: AppColors.primaryTealDark,
      error: AppColors.errorRed,
      surface: AppColors.cardWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.screenTintedBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.screenTintedBackground,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textDark),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textGray),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textLight),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: AppColors.cardWhite,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          side: const BorderSide(color: AppColors.primaryTeal),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryTeal,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardTintedWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderTeal, width: 1),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.cardWhite),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AppColors.primaryTeal : AppColors.borderGray),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AppColors.primaryTeal : AppColors.cardWhite),
        checkColor: const WidgetStatePropertyAll(AppColors.cardWhite),
        side: const BorderSide(color: AppColors.borderGray, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AppColors.primaryTeal : AppColors.textLight),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.borderGray,
        thickness: 1,
        space: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: AppColors.iconGray,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: AppColors.cardWhite,
      ),
    );
  }

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryTealAccent,
      brightness: Brightness.dark,
      primary: AppColors.primaryTealAccent,
      secondary: AppColors.primaryTeal,
      error: AppColors.errorRed,
      surface: AppColors.darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkTextPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkTextSecondary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTealAccent,
          foregroundColor: AppColors.darkBackground,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryTealAccent,
          side: const BorderSide(color: AppColors.primaryTealAccent),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryTealAccent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTealAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.darkTextPrimary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AppColors.primaryTealAccent : AppColors.darkBorder),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AppColors.primaryTealAccent : AppColors.darkCard),
        checkColor: const WidgetStatePropertyAll(AppColors.darkBackground),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? AppColors.primaryTealAccent : AppColors.darkTextSecondary),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryTealAccent,
        foregroundColor: AppColors.darkBackground,
      ),
    );
  }
}