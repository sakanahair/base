import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (LINE-style mint green theme)
  static const Color primaryColor = Color(0xFFA8D8D0);
  static const Color secondaryColor = Color(0xFF2C8075);
  static const Color hoverColor = Color(0xFF8FC4BB);
  static const Color activeBackgroundColor = Color(0xFFE8F4F2);
  
  // Background Colors
  static const Color backgroundColor = Colors.white;
  static const Color sidebarBackgroundColor = Color(0xFFF9FAFB);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Border Colors
  static const Color borderColor = Color(0xFFE5E7EB);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        error: errorColor,
      ),
      textTheme: GoogleFonts.mPlusRounded1cTextTheme().copyWith(
        displayLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.03,
          height: 1.5,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.03,
          height: 1.5,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.mPlusRounded1c(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.03,
          height: 1.5,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.03,
          height: 1.5,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.03,
          height: 1.5,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.mPlusRounded1c(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.5,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.8,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.8,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.mPlusRounded1c(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.8,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.02,
          height: 1.8,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.02,
          height: 1.8,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.mPlusRounded1c(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.02,
          height: 1.8,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.5,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.5,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.mPlusRounded1c(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
          height: 1.5,
          color: textTertiary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.mPlusRounded1c(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.02,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.mPlusRounded1c(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.02,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.mPlusRounded1c(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.02,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: GoogleFonts.mPlusRounded1c(
          fontSize: 14,
          color: textTertiary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.mPlusRounded1c(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}