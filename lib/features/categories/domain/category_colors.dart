import 'package:flutter/material.dart';

class CategoryColors {
  static const palette = <Color>[
    Color(0xFF4F46E5),
    Color(0xFF06B6D4),
    Color.fromARGB(255, 143, 128, 128),
    Color(0xFFF59E0B),
    Color.fromARGB(255, 175, 61, 61),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF84CC16),
    Color.fromARGB(255, 255, 0, 0),
    Color.fromARGB(255, 58, 58, 56),
    Color.fromARGB(255, 28, 16, 139),
    Color.fromARGB(255, 27, 224, 165),
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
