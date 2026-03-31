import 'package:finance_control/shared/widgets/app_safe_area_shell.dart';
import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSafeAreaShell(
      child: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
