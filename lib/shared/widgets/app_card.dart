import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );

    return Card(
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              onTap: onTap,
              child: content,
            ),
    );
  }
}
