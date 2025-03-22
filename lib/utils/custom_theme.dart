import 'package:flutter/material.dart';
import 'custom_colors.dart';

// This file re-exports the custom colors to maintain backward compatibility
// You can use this file in imports that previously used custom_theme.dart

extension CustomColors on ColorScheme {
  Color get accent => const Color(0xFF2DCCA7);
  Color get neutral => const Color(0xFF808080);
  Color get success => const Color(0xFF4CAF50);
  Color get warning => const Color(0xFFFFC857);
  Color get info => const Color(0xFF29B6F6);
  Color get background => const Color(0xFF121212);
  Color get cardBackground => const Color(0xFF1E1E1E);
  Color get divider => const Color(0xFF2D2D2D);
} 