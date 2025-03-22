import 'package:flutter/material.dart';

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

// Extension to allow using withValues instead of withOpacity etc
extension ColorValues on Color {
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromRGBO(
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
      alpha ?? this.opacity,
    );
  }
} 