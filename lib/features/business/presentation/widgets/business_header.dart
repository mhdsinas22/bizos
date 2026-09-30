import 'package:flutter/material.dart';
import 'package:bizos/features/business/data/models/business_model.dart';

class BusinessHeader extends StatelessWidget {
  final BusinessModel business;
  final VoidCallback onBack;
  final VoidCallback? onSettingsTap;
  final List<PopupMenuEntry<String>> Function(BuildContext)? menuItemsBuilder;
  final void Function(String)? onMenuItemSelected;

  const BusinessHeader({
    super.key,
    required this.business,
    required this.onBack,
    this.onSettingsTap,
    this.menuItemsBuilder,
    this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initial = business.name.trim().isNotEmpty
        ? business.name.trim()[0].toUpperCase()
        : 'B';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Business Avatar / Logo Squircle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF28254E), Color(0xFF1E1E38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3F3D6E)
                    : const Color(0xFFC4B5FD),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFA5B4FC)
                      : const Color(0xFF6366F1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Business Name, Type, and Active Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'biz-${business.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      business.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        business.type.isNotEmpty
                            ? business.type
                            : 'General Business',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF133827)
                            : const Color(0xFFE6F7ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action: Settings
          if (onSettingsTap != null)
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                size: 20,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
              tooltip: 'Settings',
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(38, 38),
                padding: EdgeInsets.zero,
              ),
              onPressed: onSettingsTap,
            ),

          // Action: More Menu
          if (menuItemsBuilder != null) ...[
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
              ),
              tooltip: 'More options',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(38, 38),
                padding: EdgeInsets.zero,
              ),
              itemBuilder: menuItemsBuilder!,
              onSelected: onMenuItemSelected,
            ),
          ],
        ],
      ),
    );
  }
}
