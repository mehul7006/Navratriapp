import 'package:flutter/material.dart';

class AppTheme {
  // ============================================
  // EXACT COLORS FROM INDEX.HTML
  // ============================================
  
  // Gold Colors
  static const Color goldPrimary = Color(0xFFFFB703);        // --gold-primary: #ffb703
  static const Color goldLight = Color(0xFFFFE259);           // gold-gradient start: #ffe259
  static const Color goldDark = Color(0xFFFFA751);            // gold-gradient end: #ffa751
  
  // Purple/Background Colors
  static const Color purpleDark = Color(0xFF0C0117);          // body background: #0c0117
  static const Color purpleDeep = Color(0xFF0E021E);          // header: rgba(14, 2, 30, 0.92)
  static const Color purpleCard = Color(0xFF1E0636);          // hub-item: rgba(30, 6, 54, 0.92)
  static const Color purpleAccent = Color(0xFF3D0E5C);        // phone-notch, phone-container border
  static const Color purpleSplash = Color(0xFF150024);        // splash background
  static const Color purpleModal = Color(0xFF2A0A44);         // pass-ticket gradient start
  
  // Text Colors
  static const Color textMain = Color(0xFFFFFFFF);            // --text-main: #ffffff
  static const Color textMuted = Color(0xFFF1E4FF);           // --text-muted: #f1e4ff
  
  // Accent Colors
  static const Color redAccent = Color(0xFFE63946);           // society-pill background
  static const Color cyanAccent = Color(0xFF00F2FE);          // verified text, loading text
  static const Color yellowLight = Color(0xFFFFE382);         // hub-live-card text
  
  // Card/Border Colors
  static const Color cardBg = Color(0xE816042A);             // --card-bg: rgba(22, 4, 42, 0.88)
  static const Color cardBorder = Color(0x8CFFB703);         // --card-border: rgba(255, 183, 3, 0.55)
  
  // Gradients (Exact from CSS)
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFE259), Color(0xFFFFA751)],           // linear-gradient(135deg, #ffe259 0%, #ffa751 100%)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroTitleGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFD875)],           // linear-gradient(180deg, #ffffff 30%, #ffd875 100%)
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0C0117),                                       // body background
      Color(0xFF140228),                                       // slightly lighter
      Color(0xFF0A0114),                                       // darker bottom
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient liveCardGradient = LinearGradient(
    colors: [
      Color(0xE0E63946),                                       // rgba(230, 57, 70, 0.88)
      Color(0xF22D084A),                                       // rgba(45, 8, 74, 0.95)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient passGradient = LinearGradient(
    colors: [
      Color(0xFF2A0A44),                                       // pass-ticket: #2a0a44
      Color(0xFF120120),                                       // pass-ticket: #120120
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================
  // THEME DATA
  // ============================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: goldPrimary,
      scaffoldBackgroundColor: purpleDark,
      
      colorScheme: const ColorScheme.dark(
        primary: goldPrimary,
        secondary: goldDark,
        surface: purpleDeep,
        onPrimary: purpleDark,
        onSecondary: purpleDark,
        onSurface: textMain,
      ),
      
      fontFamily: 'Outfit',
      
      textTheme: const TextTheme(
        // Hero Title: font-family: 'Cinzel', serif; font-size: clamp(2.3rem, 6.5vw, 4.4rem); font-weight: 900
        headlineLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: goldPrimary,
        ),
        // Section Header: font-family: 'Cinzel', serif; font-size: clamp(1.6rem, 3.5vw, 2.3rem); font-weight: 700
        headlineMedium: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: goldPrimary,
        ),
        // Brand Text h2: font-family: 'Cinzel', serif; font-size: clamp(1.1rem, 2.5vw, 1.4rem); font-weight: 700
        titleLarge: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: goldPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textMain,
        ),
        // Body text: font-size: clamp(1rem, 2vw, 1.25rem)
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textMuted,
          height: 1.5,
        ),
        // .hub-item span: font-size: 0.78rem
        bodyMedium: TextStyle(
          fontSize: 12,
          color: textMain,
        ),
        // Small text: font-size: 0.72rem
        bodySmall: TextStyle(
          fontSize: 11,
          color: textMuted,
          letterSpacing: 1,
        ),
      ),
      
      // Card Theme: .hub-item background, border, radius
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),            // --radius-sm: 14px
          side: const BorderSide(
            color: cardBorder,
            width: 1,
          ),
        ),
      ),
      
      // Elevated Button: .btn-gold style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldPrimary,
          foregroundColor: purpleDark,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),          // border-radius: 30px
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          elevation: 8,
          shadowColor: const Color(0x80FFB703),              // box-shadow: 0 8px 25px rgba(255, 183, 3, 0.5)
        ),
      ),
      
      // AppBar Theme: header.main-header
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xEB0E021E),                  // rgba(14, 2, 30, 0.92)
        foregroundColor: goldPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: goldPrimary,
        ),
        iconTheme: IconThemeData(color: goldPrimary),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xEB0E021E),
        selectedItemColor: goldPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x8016042A),                  // rgba(22, 4, 42, 0.5)
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: goldPrimary, width: 2),
        ),
        prefixIconColor: goldPrimary,
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: const TextStyle(color: textMain),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: cardBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  
  // Box decoration for cards matching .hub-item
  static BoxDecoration get hubItemDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: cardBorder),
    boxShadow: [
      BoxShadow(
        color: const Color(0x1A000000),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Box decoration for live card matching .hub-live-card
  static BoxDecoration get liveCardDecoration => BoxDecoration(
    gradient: liveCardGradient,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: goldPrimary),
  );

  // Box decoration for countdown bar matching .countdown-bar
  static BoxDecoration get countdownDecoration => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(22),                  // --radius-md: 22px
    border: Border.all(color: cardBorder, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: const Color(0xCC000000),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
    ],
  );

  // Box decoration for society pill matching .society-pill
  static BoxDecoration get societyPillDecoration => BoxDecoration(
    color: const Color(0x66E63946),                          // rgba(230, 57, 70, 0.4)
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: const Color(0xB3FFB703),                        // rgba(255, 183, 3, 0.7)
    ),
  );

  // Box decoration for pass ticket matching .pass-ticket
  static BoxDecoration get passTicketDecoration => BoxDecoration(
    gradient: passGradient,
    borderRadius: BorderRadius.circular(32),                  // --radius-lg: 32px
    border: Border.all(color: goldPrimary, width: 2),
    boxShadow: [
      BoxShadow(
        color: const Color(0x80FFB703),                      // box-shadow: 0 0 45px rgba(255, 183, 3, 0.5)
        blurRadius: 45,
        spreadRadius: 2,
      ),
    ],
  );

  // Box decoration for phone container matching .phone-container
  static BoxDecoration get phoneContainerDecoration => BoxDecoration(
    color: const Color(0xFF0F021E),
    borderRadius: BorderRadius.circular(46),
    border: Border.all(color: purpleAccent, width: 8),
    boxShadow: [
      const BoxShadow(
        color: Color(0xE6000000),
        blurRadius: 60,
        offset: Offset(0, 25),
      ),
      BoxShadow(
        color: const Color(0x59FFB703),
        blurRadius: 35,
      ),
    ],
  );
}
