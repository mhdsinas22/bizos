import 'package:flutter/material.dart';

class BusinessModuleCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final String? footerLeft;
  final String? footerRight;
  final Color? footerRightColor;
  final bool footerIsDivided;
  final Color? chevronColor;
  final VoidCallback? onTap;
  final bool isFullWidth;
  final bool isEnabled;

  const BusinessModuleCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    this.footerLeft,
    this.footerRight,
    this.footerRightColor,
    this.footerIsDivided = false,
    this.chevronColor,
    this.onTap,
    this.isFullWidth = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF111728)
        : Colors.white;

    final borderColor = isDark
        ? const Color(0xFF202B42)
        : const Color(0xFFEAEFF5);

    final titleColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);

    final descColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final iconBg = isDark
        ? accentColor.withValues(alpha: 0.16)
        : accentColor.withValues(alpha: 0.12);

    final effectiveChevronColor = chevronColor ??
        (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    if (isFullWidth) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 21,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isEnabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                  size: 20,
                  color: isEnabled ? effectiveChevronColor : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon squircle + (Title, Chevron, Description)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isEnabled
                                  ? Icons.chevron_right_rounded
                                  : Icons.lock_outline_rounded,
                              size: 16,
                              color: isEnabled
                                  ? effectiveChevronColor
                                  : Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: descColor,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom Area: Footers
              if (footerIsDivided &&
                  footerLeft != null &&
                  footerRight != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        footerLeft!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: descColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isDark
                          ? const Color(0xFF26304D)
                          : const Color(0xFFE2E8F0),
                    ),
                    Expanded(
                      child: Text(
                        footerRight!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: descColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else if ((footerLeft != null && footerLeft!.isNotEmpty) ||
                  (footerRight != null && footerRight!.isNotEmpty)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (footerLeft != null && footerLeft!.isNotEmpty)
                      Flexible(
                        child: Text(
                          footerLeft!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: descColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (footerRight != null && footerRight!.isNotEmpty)
                      Flexible(
                        child: Text(
                          footerRight!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: footerRightColor ?? accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

