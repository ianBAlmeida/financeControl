import 'package:flutter/material.dart';

class QuickActionsItems {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionsItems({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.items});

  final List<QuickActionsItems> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.98, // <- antes estava muito "deitado"
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: item.onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2340),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3A4D8F)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 20, color: const Color(0xFF8B5CF6)),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
