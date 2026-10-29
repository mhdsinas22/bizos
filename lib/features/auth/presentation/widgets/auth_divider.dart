import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({super.key, this.text = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final textColor = isDark
        ? AppTheme.darkTextSecondary
        : const Color(0xFF94A3B8);

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1, height: 1)),
      ],
    );
  }
}
