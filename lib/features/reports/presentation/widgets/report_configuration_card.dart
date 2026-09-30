import 'package:flutter/material.dart';
import 'package:bizos/features/business/data/models/business_model.dart';

/// Configuration controls for the Reports screen matching the reference UI.
/// Provides 3 interactive selector cards for Business Entity, Statement Type, and Date Range.
class ReportConfigurationCard extends StatelessWidget {
  final BusinessModel? selectedBusiness;
  final List<BusinessModel> businesses;
  final ValueChanged<BusinessModel> onBusinessChanged;

  final String selectedReportType;
  final List<String> reportTypes;
  final ValueChanged<String> onReportTypeChanged;

  final String dateRangeLabel;
  final VoidCallback onDateRangeTap;

  const ReportConfigurationCard({
    super.key,
    required this.selectedBusiness,
    required this.businesses,
    required this.onBusinessChanged,
    required this.selectedReportType,
    required this.reportTypes,
    required this.onReportTypeChanged,
    required this.dateRangeLabel,
    required this.onDateRangeTap,
  });

  void _showBusinessPicker(BuildContext context) {
    if (businesses.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1524) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF1E283D) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF28254E)
                            : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF6366F1),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Business Entity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: businesses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final b = businesses[index];
                    final isSelected = b.id == selectedBusiness?.id;

                    return Material(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF1E2538)
                                : const Color(0xFFF3F0FF))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onBusinessChanged(b);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF161F30)
                                      : const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    b.name.isNotEmpty
                                        ? b.name[0].toUpperCase()
                                        : 'B',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isDark
                                          ? const Color(0xFFA5B4FC)
                                          : const Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.name,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFFF8FAFC)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (b.type.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        b.type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportTypePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1524) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF1E283D) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF28254E)
                            : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: isDark
                            ? const Color(0xFFA5B4FC)
                            : const Color(0xFF6366F1),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Statement Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: reportTypes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final type = reportTypes[index];
                    final isSelected = type == selectedReportType;
                    final icon = _getReportTypeIcon(type);

                    return Material(
                      color: isSelected
                          ? (isDark
                                ? const Color(0xFF1E2538)
                                : const Color(0xFFF3F0FF))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onReportTypeChanged(type);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF161F30)
                                      : const Color(0xFFEDE9FE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  icon,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFFA5B4FC)
                                      : const Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFF8FAFC)
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getReportTypeIcon(String type) {
    if (type.contains('Analytics')) return Icons.analytics_rounded;
    if (type.contains('Profit')) return Icons.pie_chart_rounded;
    if (type.contains('Income')) return Icons.trending_up_rounded;
    if (type.contains('Expense')) return Icons.trending_down_rounded;
    if (type.contains('Task')) return Icons.task_alt_rounded;
    if (type.contains('Staff')) return Icons.badge_rounded;
    return Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Select Business Entity
        _buildSelectorCard(
          context: context,
          icon: Icons.storefront_rounded,
          label: 'Select Business Entity',
          value: selectedBusiness?.name ?? 'Select Business',
          onTap: () => _showBusinessPicker(context),
        ),
        const SizedBox(height: 12),

        // 2. Select Statement Type
        _buildSelectorCard(
          context: context,
          icon: Icons.description_rounded,
          label: 'Select Statement Type',
          value: selectedReportType,
          onTap: () => _showReportTypePicker(context),
        ),
        const SizedBox(height: 12),

        // 3. Date Range Scope
        _buildSelectorCard(
          context: context,
          icon: Icons.calendar_month_rounded,
          label: 'Date Range Scope',
          value: dateRangeLabel,
          onTap: onDateRangeTap,
        ),
      ],
    );
  }

  Widget _buildSelectorCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF111728) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E283D)
        : const Color(0xFFE2E8F0);
    final iconBg = isDark ? const Color(0xFF28254E) : const Color(0xFFEDE9FE);
    final iconColor = isDark
        ? const Color(0xFFA5B4FC)
        : const Color(0xFF6366F1);
    final labelColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final valueColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Squircle Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Icon(icon, size: 20, color: iconColor)),
                ),
                const SizedBox(width: 12),

                // Center (Label + Value)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Dropdown caret
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 24,
                  color: labelColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
