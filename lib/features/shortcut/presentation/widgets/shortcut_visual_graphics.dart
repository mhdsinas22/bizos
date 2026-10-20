import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class QuickAddPhoneHero extends StatelessWidget {
  const QuickAddPhoneHero({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: 260,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft Background Glow
            Positioned(
              top: 20,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(
                    alpha: isDark ? 0.25 : 0.12,
                  ),
                ),
              ),
            ),

            // Tilted iPhone Device Body
            Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 170,
                height: 230,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B4863)
                        : const Color(0xFFCBD5E1),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(4, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Column(
                  children: [
                    // Dynamic Island / Speaker Pill
                    Container(
                      width: 44,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Floating Expense Card 1: Coffee ₹120
                    _buildFloatingMiniCard(
                      icon: Icons.coffee_rounded,
                      iconColor: const Color(0xFFD97706),
                      title: 'Coffee',
                      amount: '₹120',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // Floating Expense Card 2: Car Fuel ₹2,500
                    _buildFloatingMiniCard(
                      icon: Icons.directions_car_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      title: 'Car Fuel',
                      amount: '₹2,500',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // Floating Expense Card 3: Shopping ₹450
                    _buildFloatingMiniCard(
                      icon: Icons.shopping_bag_rounded,
                      iconColor: const Color(0xFFEC4899),
                      title: 'Shopping',
                      amount: '₹450',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Overlapping Lightning Bolt Badge
            Positioned(
              left: 12,
              bottom: 40,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingMiniCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2B354C) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class SiriOrbGraphic extends StatelessWidget {
  const SiriOrbGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          // Main Siri Iridescent Gradient Sphere
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF38BDF8),
                  Color(0xFF818CF8),
                  Color(0xFFC084FC),
                  Color(0xFFF472B6),
                  Color(0xFF38BDF8),
                ],
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    const Color(0xFFC084FC).withValues(alpha: 0.6),
                    const Color(0xFF38BDF8).withValues(alpha: 0.7),
                    const Color(0xFF1E1B4B),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SiriPhraseCard extends StatelessWidget {
  final String phrase;

  const SiriPhraseCard({
    super.key,
    required this.phrase,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '“',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              height: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              phrase,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
