import 'package:bizos/core/constants/app_images.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  final double logoSize;
  final String? subtitle;
  final double brandFontSize;

  const AuthBrandHeader({
    super.key,
    this.logoSize = 72,
    this.subtitle,
    this.brandFontSize = 27,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF7CB832,
                ).withValues(alpha: isDark ? 0.16 : 0.14),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            AppImages.hapticGradientLogo,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Haptic',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: brandFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF0F172A),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : const Color(0xFF64748B),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }
}
