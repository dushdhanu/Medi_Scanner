import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00696B); // Deep Medical Teal
  static const Color primaryLight = Color(0xFF26A69A);
  static const Color primaryDark = Color(0xFF004D40);
  
  static const Color secondaryColor = Color(0xFF0288D1); // Clinical Blue
  static const Color accentColor = Color(0xFF2E7D32); // Health Green
  static const Color warningColor = Color(0xFFE65100); // Amber/Orange warning
  static const Color dangerColor = Color(0xFFC62828); // Caution red

  static const Color surfaceLight = Color(0xFFF7FBFB);
  static const Color surfaceDark = Color(0xFF0F1515);

  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF192222);

  static ThemeData lightTheme() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: surfaceLight,
      textTheme: baseTextTheme.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF191C1C)),
        headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF191C1C)),
        titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF191C1C)),
        titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: const Color(0xFF191C1C)),
        bodyLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: const Color(0xFF2C3131)),
        bodyMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: const Color(0xFF3F4848)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF191C1C),
        ),
        iconTheme: IconThemeData(color: Color(0xFF191C1C)),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0EAE9), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFF6F7978),
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: const Color(0xFFE0EAE9),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    );
  }

  static ThemeData darkTheme() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLight,
        brightness: Brightness.dark,
        primary: primaryLight,
        secondary: const Color(0xFF4FC3F7),
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: surfaceDark,
      textTheme: baseTextTheme.copyWith(
        displaySmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white),
        titleLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: const Color(0xFFE0E3E3)),
        bodyMedium: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400, color: const Color(0xFFBEC8C8)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF283434), width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: const Color(0xFF003737),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryLight,
        unselectedLabelColor: const Color(0xFF899392),
        indicatorColor: primaryLight,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: const Color(0xFF283434),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
    );
  }
}
