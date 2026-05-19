import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VintageTheme {
  // Brand Palette: Tactile, organic, sepia and ink
  static const Color parchmentLight = Color(0xFFFDFBF7);
  static const Color parchmentDark = Color(0xFFF4EFE3);
  static const Color inkBlue = Color(0xFF1E2D4A);
  static const Color waxSealRed = Color(0xFF8B2525);
  static const Color antiqueGold = Color(0xFFC5A059);
  static const Color paperBorder = Color(0xFFDCD5C5);
  static const Color shadowColor = Color(0x1F2C3E50);

  // Border decoration simulating a classic ink line border or parchment card
  static BoxDecoration paperCardDecoration({bool doubleBorder = false}) {
    return BoxDecoration(
      color: parchmentLight,
      borderRadius: BorderRadius.circular(4),
      boxShadow: const [
        BoxShadow(
          color: shadowColor,
          blurRadius: 10,
          offset: Offset(2, 4),
        )
      ],
      border: Border.all(
        color: paperBorder,
        width: 1.5,
      ),
    );
  }

  // Dual outer/inner line border aesthetic common in vintage books/documents
  static BoxDecoration vintageBorder() {
    return BoxDecoration(
      border: Border.all(color: inkBlue, width: 2),
    );
  }

  // Get full Material Theme
  static ThemeData getThemeData() {
    final baseTextTheme = GoogleFonts.ebGaramondTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: parchmentDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: inkBlue,
        onPrimary: parchmentLight,
        secondary: antiqueGold,
        onSecondary: inkBlue,
        error: waxSealRed,
        onError: parchmentLight,
        surface: parchmentLight,
        onSurface: inkBlue,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.ebGaramond(
          fontWeight: FontWeight.bold,
          color: inkBlue,
        ),
        headlineMedium: GoogleFonts.ebGaramond(
          fontWeight: FontWeight.w600,
          color: inkBlue,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.ebGaramond(
          color: inkBlue,
          fontSize: 18,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.ebGaramond(
          color: inkBlue,
          fontSize: 16,
          height: 1.4,
        ),
      ),
      // Hand-written font style specifically for the writing surface
      extensions: [
        VintageWritingStyle(
          handwritingStyle: GoogleFonts.caveat(
            color: inkBlue,
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w500,
          ),
          typewriterStyle: GoogleFonts.specialElite(
            color: inkBlue,
            fontSize: 18,
            height: 1.4,
          ),
        )
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: parchmentDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.ebGaramond(
          color: inkBlue,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: inkBlue),
      ),
      cardTheme: CardThemeData(
        color: parchmentLight,
        elevation: 4,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: paperBorder, width: 1),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: inkBlue,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}

// Custom extensions for specialized vintage writing interfaces
class VintageWritingStyle extends ThemeExtension<VintageWritingStyle> {
  final TextStyle handwritingStyle;
  final TextStyle typewriterStyle;

  VintageWritingStyle({
    required this.handwritingStyle,
    required this.typewriterStyle,
  });

  @override
  ThemeExtension<VintageWritingStyle> copyWith({
    TextStyle? handwritingStyle,
    TextStyle? typewriterStyle,
  }) {
    return VintageWritingStyle(
      handwritingStyle: handwritingStyle ?? this.handwritingStyle,
      typewriterStyle: typewriterStyle ?? this.typewriterStyle,
    );
  }

  @override
  ThemeExtension<VintageWritingStyle> lerp(
    ThemeExtension<VintageWritingStyle>? other,
    double t,
  ) {
    if (other is! VintageWritingStyle) return this;
    return VintageWritingStyle(
      handwritingStyle: TextStyle.lerp(handwritingStyle, other.handwritingStyle, t)!,
      typewriterStyle: TextStyle.lerp(typewriterStyle, other.typewriterStyle, t)!,
    );
  }
}
