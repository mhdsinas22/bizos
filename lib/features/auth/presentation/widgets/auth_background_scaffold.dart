import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthBackgroundScaffold extends StatelessWidget {
  final Widget child;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? topRightAction;
  final bool topWaveOnLeft;
  final EdgeInsetsGeometry contentPadding;

  const AuthBackgroundScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
    this.onBackPressed,
    this.topRightAction,
    this.topWaveOnLeft = false,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 12.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : const Color(0xFFF8FAF7);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft organic mint/green background waves matching mockup
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AuthOrganicWavePainter(
                  isDark: isDark,
                  topWaveOnLeft: topWaveOnLeft,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (showBackButton || topRightAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
                    child: SizedBox(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (showBackButton)
                            IconButton(
                              onPressed:
                                  onBackPressed ??
                                  () => Navigator.of(context).maybePop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : const Color(0xFF0F172A),
                              ),
                              tooltip: 'Back',
                            )
                          else
                            const SizedBox(width: 44),
                          ?topRightAction,
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: contentPadding,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthOrganicWavePainter extends CustomPainter {
  final bool isDark;
  final bool topWaveOnLeft;

  _AuthOrganicWavePainter({required this.isDark, required this.topWaveOnLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final topPath = Path();
    if (topWaveOnLeft) {
      topPath.moveTo(0, 0);
      topPath.lineTo(size.width * 0.72, 0);
      topPath.quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.08,
        size.width * 0.25,
        size.height * 0.16,
      );
      topPath.quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.22,
        0,
        size.height * 0.26,
      );
      topPath.close();
    } else {
      topPath.moveTo(size.width, 0);
      topPath.lineTo(size.width * 0.35, 0);
      topPath.quadraticBezierTo(
        size.width * 0.62,
        size.height * 0.07,
        size.width * 0.78,
        size.height * 0.15,
      );
      topPath.quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.21,
        size.width,
        size.height * 0.24,
      );
      topPath.close();
    }

    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: topWaveOnLeft ? Alignment.topLeft : Alignment.topRight,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                AppTheme.primaryColor.withValues(alpha: 0.10),
                AppTheme.primaryColor.withValues(alpha: 0.02),
              ]
            : [
                const Color(0xFFE7F3D7).withValues(alpha: 0.85),
                const Color(0xFFF1F8E7).withValues(alpha: 0.35),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.3));

    canvas.drawPath(topPath, topPaint);

    // Bottom left organic wave
    final bottomLeftPath = Path();
    bottomLeftPath.moveTo(0, size.height);
    bottomLeftPath.lineTo(0, size.height * 0.84);
    bottomLeftPath.quadraticBezierTo(
      size.width * 0.16,
      size.height * 0.88,
      size.width * 0.34,
      size.height * 0.95,
    );
    bottomLeftPath.quadraticBezierTo(
      size.width * 0.44,
      size.height * 0.985,
      size.width * 0.52,
      size.height,
    );
    bottomLeftPath.close();

    final bottomPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: isDark
                ? [
                    AppTheme.primaryColor.withValues(alpha: 0.10),
                    AppTheme.primaryColor.withValues(alpha: 0.02),
                  ]
                : [
                    const Color(0xFFE3F1CF).withValues(alpha: 0.9),
                    const Color(0xFFEEF7E3).withValues(alpha: 0.35),
                  ],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.8, size.width, size.height * 0.2),
          );

    canvas.drawPath(bottomLeftPath, bottomPaint);

    // Bottom right subtle wave
    final bottomRightPath = Path();
    bottomRightPath.moveTo(size.width, size.height);
    bottomRightPath.lineTo(size.width * 0.58, size.height);
    bottomRightPath.quadraticBezierTo(
      size.width * 0.78,
      size.height * 0.94,
      size.width,
      size.height * 0.89,
    );
    bottomRightPath.close();

    canvas.drawPath(bottomRightPath, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant _AuthOrganicWavePainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.topWaveOnLeft != topWaveOnLeft;
  }
}
