import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';

class VorynNavDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const VorynNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class VorynBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<VorynNavDestination> destinations;

  const VorynBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) return const SizedBox.shrink();

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIOS) {
      return _buildIOSNavBar(context);
    } else {
      return _buildMaterialNavBar(context);
    }
  }

  Widget _buildIOSNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final primaryColor = isDark
        ? AppTheme.primaryLightColor
        : AppTheme.primaryColor;
    final inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: 6,
            bottom: bottomPadding > 0 ? bottomPadding : 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final dest = destinations[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onDestinationSelected(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active Pill Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: destinations.length > 4 ? 10 : 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark
                                  ? AppTheme.primaryColor.withValues(alpha: 0.25)
                                  : const Color(0xFFEDE9FE))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isSelected ? dest.selectedIcon : dest.icon,
                          size: destinations.length > 4 ? 20 : 22,
                          color: isSelected ? primaryColor : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dest.label,
                        style: TextStyle(
                          fontSize: destinations.length > 4 ? 9.5 : 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? primaryColor : inactiveColor,
                          letterSpacing: destinations.length > 4 ? -0.4 : -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialNavBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedLabelColor = isDark
        ? AppTheme.primaryLightColor
        : AppTheme.primaryColor;
    final unselectedLabelColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final navBarTheme = NavigationBarThemeData(
      height: 66.0,
      elevation: 0,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      indicatorColor: isDark
          ? AppTheme.primaryColor.withValues(alpha: 0.22)
          : const Color(0xFFEDE9FE),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.0,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? selectedLabelColor : unselectedLabelColor,
          letterSpacing: -0.2,
          height: 1.1,
          overflow: TextOverflow.ellipsis,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 22.0,
          color: isSelected ? selectedLabelColor : unselectedLabelColor,
        );
      }),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        left: true,
        right: true,
        bottom: true,
        child: NavigationBarTheme(
          data: navBarTheme,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations.map((destination) {
              return NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
                tooltip: destination.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
