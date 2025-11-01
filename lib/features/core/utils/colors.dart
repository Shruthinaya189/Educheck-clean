import 'package:flutter/material.dart';

class AppColors {
  // Primary Theme Colors (Professional and Modern)
  static const Color primaryBlue = Color(0xFF4568DC); // Strong primary
  static const Color primaryPurple = Color(0xFFB06AB3); // Primary accent
  static const Color accentOrange = Color(0xFFFC5C7D); // Action/Alert color
  static const Color darkBackground = Color(0xFF1A1A2E); // Dark mode background
  static const Color lightBackground = Color(0xFFF7F7F7); // Light mode background

  // Gradient Definitions for Class Cards
  static const List<Color> mathGradient = [Color(0xFF6A82FB), Color(0xFFFC5C7D)]; 
  static const List<Color> scienceGradient = [Color(0xFF2196F3), Color(0xFF4CAF50)];
  static const List<Color> historyGradient = [Color(0xFFff9966), Color(0xFFff5e62)];
  static const List<Color> englishGradient = [Color(0xFFa8ff78), Color(0xFF78ffd6)];

  static const LinearGradient appBackgroundGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}