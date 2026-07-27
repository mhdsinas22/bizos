import 'package:bizos/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class HistorySkeletonLoader extends StatelessWidget {
  const HistorySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 10,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 60,
                  height: 16,
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
