import 'package:flutter/material.dart';

class AppGradientScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool useSafeArea;

  const AppGradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = useSafeArea ? SafeArea(child: body) : body;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070B1A), Color.fromARGB(255, 6, 5, 65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: content,
      ),
    );
  }
}
