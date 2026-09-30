import 'package:flutter/material.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_profile_sheet.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_settings_sheet.dart';

/// Clean, responsive Top App Bar for the Voryn ERP Dashboard.
/// Displays app branding, role context, Settings button, and Profile button.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel user;

  const DashboardAppBar({
    super.key,
    required this.user,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      titleSpacing: 16,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.primaryColor.withValues(alpha: 0.22)
                  : AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              size: 19,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Voryn ERP',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                user.isOwner ? 'Owner Console' : '${user.name} (${user.role})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Settings icon button
        InkWell(
          onTap: () => DashboardSettingsSheet.show(context),
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 19,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Profile icon button
        InkWell(
          onTap: () => DashboardProfileSheet.show(context, user),
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 19,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
