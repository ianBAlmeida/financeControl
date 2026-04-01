import 'package:flutter/material.dart';

class CategoryColors {
  static const palette = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
  ];

  static Color byId(String id) {
    final idx = id.runes.fold(0, (p, e) => p + e) % palette.length;
    return palette[idx];
  }

  static Color hexToColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  static String colorToHex(Color color) {
    final raw = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    return '#${raw.toUpperCase()}';
  }
}
