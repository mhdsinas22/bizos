import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum InstructionCardType {
  openSettings,
  tapTouch,
  enableBackTap,
  chooseDoubleTap,
  selectShortcut,
}

class ShortcutInstructionCard extends StatelessWidget {
  final InstructionCardType type;

  const ShortcutInstructionCard({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131926) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(context, isDark),
          _buildCardBody(context, isDark),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context, bool isDark) {
    switch (type) {
      case InstructionCardType.openSettings:
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 16,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case InstructionCardType.tapTouch:
        return _buildSubpageHeader(
          context,
          parent: 'Settings',
          title: 'Accessibility',
          isDark: isDark,
        );

      case InstructionCardType.enableBackTap:
        return _buildSubpageHeader(
          context,
          parent: 'Accessibility',
          title: 'Touch',
          isDark: isDark,
        );

      case InstructionCardType.chooseDoubleTap:
        return _buildSubpageHeader(
          context,
          parent: 'Touch',
          title: 'Back Tap',
          isDark: isDark,
        );

      case InstructionCardType.selectShortcut:
        return _buildSubpageHeader(
          context,
          parent: 'Back Tap',
          title: 'Double Tap',
          isDark: isDark,
        );
    }
  }

  Widget _buildSubpageHeader(
    BuildContext context, {
    required String parent,
    required String title,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          Text(
            parent,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBody(BuildContext context, bool isDark) {
    switch (type) {
      case InstructionCardType.openSettings:
        return Column(
          children: [
            _buildSettingsRow(
              icon: Icons.settings,
              iconBg: Colors.grey,
              title: 'General',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.accessibility_new_rounded,
              iconBg: const Color(0xFF4F46E5),
              title: 'Accessibility',
              isHighlighted: true,
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.touch_app_rounded,
              iconBg: Colors.blueAccent,
              title: 'Action Button',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.camera_alt_rounded,
              iconBg: Colors.blueGrey,
              title: 'Camera',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.tune_rounded,
              iconBg: Colors.grey,
              title: 'Control Center',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.brightness_6_rounded,
              iconBg: Colors.blue,
              title: 'Display & Brightness',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.apps_rounded,
              iconBg: Colors.purple,
              title: 'Home Screen & App Library',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.search_rounded,
              iconBg: Colors.teal,
              title: 'Search',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.graphic_eq_rounded,
              iconBg: Colors.deepPurple,
              title: 'Siri',
              isDark: isDark,
              isLast: true,
            ),
          ],
        );

      case InstructionCardType.tapTouch:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text(
                'Physical and Motor',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
            _buildSettingsRow(
              icon: Icons.touch_app_rounded,
              iconBg: const Color(0xFF4F46E5),
              title: 'Touch',
              isHighlighted: true,
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.face_rounded,
              iconBg: Colors.green,
              title: 'Face ID & Attention',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.toggle_off_rounded,
              iconBg: Colors.grey,
              title: 'Switch Control',
              trailingText: 'Off',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.record_voice_over_rounded,
              iconBg: Colors.blue,
              title: 'Voice Control',
              trailingText: 'Off',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.power_settings_new_rounded,
              iconBg: Colors.blueGrey,
              title: 'Side Button',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.devices_rounded,
              iconBg: Colors.indigo,
              title: 'Control Nearby Devices',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.tv_rounded,
              iconBg: Colors.grey,
              title: 'Apple TV Remote',
              isDark: isDark,
            ),
            _buildSettingsRow(
              icon: Icons.keyboard_rounded,
              iconBg: Colors.grey,
              title: 'Keyboards',
              isDark: isDark,
              isLast: true,
            ),
          ],
        );

      case InstructionCardType.enableBackTap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsRow(
              title: 'AssistiveTouch',
              trailingText: 'Off',
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'AssistiveTouch allows you to use your iPhone if you have difficulty touching the screen.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildToggleRow(
              title: 'Reachability',
              value: true,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Swipe down on the bottom edge of the screen to bring the top into reach.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              title: 'Back Tap',
              trailingText: 'On',
              isHighlighted: true,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Double- or triple-tap the back of your iPhone to perform actions quickly.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        );

      case InstructionCardType.chooseDoubleTap:
        return Column(
          children: [
            _buildSettingsRow(
              title: 'Double Tap',
              isHighlighted: true,
              isDark: isDark,
            ),
            _buildSettingsRow(
              title: 'Triple Tap',
              isDark: isDark,
            ),
            _buildToggleRow(
              title: 'Show Banner',
              value: true,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
        );

      case InstructionCardType.selectShortcut:
        return Column(
          children: [
            _buildSettingsRow(
              title: 'None',
              showArrow: false,
              isDark: isDark,
            ),
            _buildShortcutSelectionRow(
              title: 'Voryn – Quick Add Expense',
              isSelected: true,
              isDark: isDark,
            ),
            _buildSettingsRow(
              title: 'Open App...',
              leadingIcon: Icons.open_in_new_rounded,
              leadingBg: Colors.blue,
              showArrow: false,
              isDark: isDark,
            ),
            _buildSettingsRow(
              title: 'Shortcut...',
              leadingIcon: Icons.auto_awesome_rounded,
              leadingBg: Colors.amber,
              showArrow: false,
              isDark: isDark,
              isLast: true,
            ),
          ],
        );
    }
  }

  Widget _buildSettingsRow({
    IconData? icon,
    Color? iconBg,
    IconData? leadingIcon,
    Color? leadingBg,
    required String title,
    String? trailingText,
    bool isHighlighted = false,
    bool showArrow = true,
    bool isLast = false,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
            : Colors.transparent,
        border: isHighlighted
            ? Border.all(
                color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.6 : 0.4),
                width: 1.5,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconBg ?? Colors.grey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ] else if (leadingIcon != null) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: leadingBg ?? Colors.grey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(leadingIcon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                color: isHighlighted
                    ? (isDark ? Colors.white : AppTheme.primaryColor)
                    : (isDark ? Colors.white : AppTheme.lightTextPrimary),
              ),
            ),
          ),
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (showArrow)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isHighlighted
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white30 : Colors.black26),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required bool value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: const Color(0xFF34C759),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSelectionRow({
    required String title,
    required bool isSelected,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.7 : 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
          if (isSelected)
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
