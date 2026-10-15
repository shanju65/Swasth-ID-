import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient (Medical Blue -> Teal)
  static const Color primaryColor = Color(0xFF0D47A1); // Deep Blue
  static const Color primaryLight = Color(0xFF42A5F5); // Lighter Blue
  static const Color tealAccent = Color(0xFF00BFA5); // Medical Teal
  
  // Backgrounds
  static const Color backgroundColor = Color(0xFFF8F9FA); // Soft Off-White
  static const Color surfaceColor = Colors.white;
  
  // Text
  static const Color textColor = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6C757D);
  
  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);
  
  // Gradient for Buttons/Scaffold
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF009688), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
