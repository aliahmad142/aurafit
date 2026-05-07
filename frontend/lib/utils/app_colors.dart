import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B1020);
  static const Color surface = Color(0xFF151A2E);
  
  // Accents
  static const Color primary = Color(0xFF7C5CFF);
  static const Color secondary = Color(0xFF38BDF8);
  static const Color champagne = Color(0xFFE8DCC8);
  
  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  // Borders & Glass
  static const Color border = Color(0x33FFFFFF);
  static const Color glassMap = Color(0x1AFFFFFF);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
