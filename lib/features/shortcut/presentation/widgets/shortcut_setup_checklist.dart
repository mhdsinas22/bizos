import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ShortcutSetupChecklist extends StatelessWidget {
  final bool isShortcutAdded;
  final bool isBackTapConfigured;
  final bool isReady;

  const ShortcutSetupChecklist({
    super.key,
    this.isShortcutAdded = true,
    this.isBackTapConfigured = true,
    this.isReady = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildCheckItem(
            label: 'Shortcut added to your library',
            isChecked: isShortcutAdded,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCheckItem(
            label: 'Back Tap configured',
            isChecked: isBackTapConfigured,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCheckItem(
            label: 'Ready to add expenses',
            isChecked: isReady,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool isChecked,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isChecked
                ? AppTheme.primaryColor
                : (isDark ? Colors.white12 : Colors.black12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isChecked ? Icons.check_rounded : Icons.circle,
            size: isChecked ? 15 : 6,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class CelebrationCheckmarkGraphic extends StatelessWidget {
  final Color circleColor;
  final IconData icon;

  const CelebrationCheckmarkGraphic({
    super.key,
    this.circleColor = AppTheme.primaryColor,
    this.icon = Icons.check_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radiating Confetti Burst
          ...List.generate(8, (i) {
            final angle = i * (3.14159 / 4);
            const distance = 44.0;
            return Transform.translate(
              offset: Offset(
                distance * (i % 2 == 0 ? 0.9 : 0.7) * (i == 1 || i == 2 || i == 3 ? 1 : (i == 5 || i == 6 || i == 7 ? -1 : 0)),
                distance * (i % 2 == 0 ? 0.9 : 0.7) * (i == 3 || i == 4 || i == 5 ? 1 : (i == 7 || i == 0 || i == 1 ? -1 : 0)),
              ),
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 5,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i % 3 == 0
                        ? Colors.amber
                        : (i % 3 == 1 ? Colors.purpleAccent : Colors.tealAccent),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),

          // Center Circle with Checkmark
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: circleColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
