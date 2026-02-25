import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    scaffoldBackgroundColor: Colors.grey[50],
    cardTheme: const CardThemeData(
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
