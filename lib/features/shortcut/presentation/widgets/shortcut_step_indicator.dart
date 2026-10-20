import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ShortcutStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final String? stepLabel;

  const ShortcutStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 12,
    this.onBack,
    this.onClose,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                tooltip: 'Back',
              ),

              // Segmented Progress Bar
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: List.generate(
                      totalSteps > 6 ? 6 : totalSteps,
                      (index) {
                        // Map 12 steps into 6 visual indicator bars
                        final activeThreshold = ((index + 1) * (totalSteps / 6)).round();
                        final isFilled = currentStep >= activeThreshold;

                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isFilled
                                  ? AppTheme.primaryColor
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.08)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Close Button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                tooltip: 'Close',
              ),
            ],
          ),
          if (stepLabel != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                stepLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
