import 'package:flutter/material.dart';

/// Hero banner for the Reporting Console matching the Voryn ERP design reference.
/// Features a soft lavender gradient, clean typography, and a 3D report illustration.
class ReportsHero extends StatelessWidget {
  final VoidCallback? onTap;

  const ReportsHero({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    final imgWidth = isCompact ? 76.0 : 100.0;
    final imgHeight = isCompact ? 68.0 : 88.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF13192B),
                  Color(0xFF182038),
                  Color(0xFF0F1523),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F5FF),
                  Color(0xFFEBF1FF),
                  Color(0xFFF9FAFD),
                ],
              ),
        border: Border.all(
          color: isDark ? const Color(0xFF26304D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14.0 : 18.0,
              vertical: isCompact ? 14.0 : 16.0,
            ),
            child: Row(
              children: [
                // Left Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reporting Console',
                        style: TextStyle(
                          fontSize: isCompact ? 18.0 : 21.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Generate and share corporate PDF statements.',
                        style: TextStyle(
                          fontSize: isCompact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right 3D Illustration
                SizedBox(
                  width: imgWidth,
                  height: imgHeight,
                  child: Image.asset(
                    'assets/icon/reports_3d.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/png/ChatGPT Image Sep 30, 2026, 11_45_21 AM.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(
                          Icons.analytics_rounded,
                          size: 42,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
