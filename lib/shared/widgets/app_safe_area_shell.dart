import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppSafeAreaShell extends StatelessWidget {
  final Widget child;

  const AppSafeAreaShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background, // cor atrás do notch/status bar
      child: SafeArea(top: true, bottom: false, child: child),
    );
  }
}
