import 'dart:async';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BusinessReportLoadingDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const BusinessReportLoadingDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<BusinessReportLoadingDialog> createState() =>
      _BusinessReportLoadingDialogState();
}

class _BusinessReportLoadingDialogState
    extends State<BusinessReportLoadingDialog> {
  final List<String> _analysisSteps = [
    'Revenue Analysis',
    'Expense Analysis',
    'Customer Analysis',
    'Supplier Analysis',
    'Product Analysis',
    'Inventory Analysis',
    'Cash Flow Analysis',
    'Generating Charts',
    'Building Executive Summary',
    'Preparing Report',
  ];

  int _currentStepIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 320), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _analysisSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyzing Business Data...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enterprise ERP Intelligence Engine',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _analysisSteps.length,
                itemBuilder: (context, index) {
                  final isDone = index <= _currentStepIndex;
                  final isCurrent = index == _currentStepIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isDone
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                  size: 18,
                                  key: ValueKey('done'),
                                )
                              : Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  size: 18,
                                  key: const ValueKey('undone'),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _analysisSteps[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : (isDone ? FontWeight.w500 : FontWeight.normal),
                            color: isDone
                                ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                                : (isDark ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
