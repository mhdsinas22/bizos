import 'package:flutter/material.dart';

/// Hero / Welcome banner for the Voryn ERP Dashboard.
/// Displays authenticated user name, overview subtitle, and 3D store illustration.
class DashboardHeroCard extends StatelessWidget {
  final String userName;

  const DashboardHeroCard({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    final displayName = userName.isNotEmpty ? userName : 'User';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFDDD6FE).withValues(alpha: 0.7),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF181B34),
                  Color(0xFF111425),
                ]
              : const [
                  Color(0xFFF6F4FE),
                  Color(0xFFEDE9FE),
                ],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 24,
        vertical: isMobile ? 14 : 18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back, $displayName',
                  style: TextStyle(
                    fontSize: isMobile ? 19 : 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Here’s your business performance overview.',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13.5,
                    fontWeight: FontWeight.w400,
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
          // 3D Storefront Asset Illustration
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 115 : 150,
              maxHeight: isMobile ? 100 : 125,
            ),
            child: Image.asset(
              'assets/icon/store_3d.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
