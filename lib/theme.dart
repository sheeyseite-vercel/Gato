import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const green = Color(0xFF0F3B27);
  static const deep = Color(0xFF092619);
  static const lime = Color(0xFF92FF5F); // main accent (signal lime)
  static const orange = Color(0xFFFF7036);
  static const white = Color(0xFFF7F9F7);
  static const ice = Color(0xFFBFF2F0);
  static const mint = Color(0xFFCFF1D2);
  static const muted = Color(0xFFA9C9B6);
  static const eye = Color(0xFFFFFF00);
}

Color op(Color c, double o) => c.withOpacity(o);

TextStyle disp(double size, {Color color = C.white}) => GoogleFonts.fredoka(
    fontSize: size, color: color, fontWeight: FontWeight.w500, height: 1.2);

TextStyle txt(double size,
        {Color color = C.white, FontWeight w = FontWeight.w500}) =>
    GoogleFonts.dmSans(fontSize: size, color: color, fontWeight: w);

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: C.green,
    colorScheme: const ColorScheme.dark(
        primary: C.lime, onPrimary: C.green, secondary: C.orange, surface: C.green),
  );
  return base.copyWith(
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme)
        .apply(bodyColor: C.white, displayColor: C.white),
  );
}
