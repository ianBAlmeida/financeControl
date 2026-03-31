import 'package:finance_control/shared/theme/app_colors.dart';
import 'package:finance_control/shared/theme/app_spacing.dart';
import 'package:finance_control/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color? valueColor;
  final VoidCallback? onTap;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primarySoft),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
