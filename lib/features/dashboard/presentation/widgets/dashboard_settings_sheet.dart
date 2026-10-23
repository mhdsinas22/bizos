import 'package:bizos/features/shortcut/presentation/pages/quick_add_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/theme/theme_bloc.dart';
import 'package:bizos/features/ai/presentation/screens/ai_chat_screen.dart';

/// Modal bottom sheet displaying dashboard settings:
/// Theme toggle (Dark/Light mode), AI Assistant shortcut, and App info.
class DashboardSettingsSheet extends StatelessWidget {
  const DashboardSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const DashboardSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BlocBuilder<ThemeBloc, ThemeState>(
                      builder: (context, themeState) {
                        final isDarkMode = themeState.isDarkMode;
                        final selectedMode = isDarkMode
                            ? ThemeMode.dark
                            : ThemeMode.light;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkCard
                                  : AppTheme.lightBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : AppTheme.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isDarkMode
                                            ? Icons.dark_mode_rounded
                                            : Icons.light_mode_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Theme Appearance',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isDarkMode
                                                ? 'Dark theme active'
                                                : 'Light theme active (Default)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppTheme.darkTextSecondary
                                                  : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: SegmentedButton<ThemeMode>(
                                    segments: const [
                                      ButtonSegment<ThemeMode>(
                                        value: ThemeMode.light,
                                        icon: Icon(
                                          Icons.light_mode_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Light',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      ButtonSegment<ThemeMode>(
                                        value: ThemeMode.dark,
                                        icon: Icon(
                                          Icons.dark_mode_rounded,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Dark',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                    selected: {selectedMode},
                                    showSelectedIcon: true,
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      side: WidgetStateProperty.all(
                                        BorderSide(
                                          color: isDark
                                              ? AppTheme.darkBorder
                                              : AppTheme.lightBorder,
                                        ),
                                      ),
                                    ),
                                    onSelectionChanged:
                                        (Set<ThemeMode> newSelection) {
                                          if (newSelection.isNotEmpty) {
                                            context.read<ThemeBloc>().add(
                                              SetThemeEvent(newSelection.first),
                                            );
                                          }
                                        },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Voryn AI Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Ask business analytics questions',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiChatScreen(),
                          ),
                        );
                      },
                    ),

                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Personal Quick Expense',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Add expenses in just  a few taps',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QuickAddOnboardingPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'About Voryn ERP',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Version 1.0.2+5 • Production',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
