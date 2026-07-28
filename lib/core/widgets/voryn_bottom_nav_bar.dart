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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final itemCount = destinations.length;

    if (itemCount == 0) return const SizedBox.shrink();

    // Calculate exact available width per item for dynamic responsive scaling
    final itemWidth = screenWidth / itemCount;

    // Dynamically scale font size, icon size, and navbar height based on item width
    final double fontSize;
    if (itemWidth < 56) {
      fontSize = 9.5;
    } else if (itemWidth < 64) {
      fontSize = 10.0;
    } else if (itemWidth < 72) {
      fontSize = 11.0;
    } else {
      fontSize = 12.0;
    }

    final double iconSize = itemWidth < 58
        ? 20.0
        : (itemWidth < 68 ? 22.0 : 24.0);

    final double navBarHeight = itemWidth < 60
        ? 62.0
        : (itemWidth < 72 ? 66.0 : 70.0);

    final selectedLabelColor = isDark
        ? AppTheme.primaryLightColor
        : AppTheme.primaryColor;
    final unselectedLabelColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    final navBarTheme = NavigationBarThemeData(
      height: navBarHeight,
      elevation: 0,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      indicatorColor: isDark
          ? AppTheme.primaryColor.withValues(alpha: 0.22)
          : AppTheme.primaryColor.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(itemWidth < 60 ? 10 : 14),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? selectedLabelColor : unselectedLabelColor,
          letterSpacing: itemWidth < 64 ? -0.4 : -0.2,
          height: 1.1,
          overflow: TextOverflow.ellipsis,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: iconSize,
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
