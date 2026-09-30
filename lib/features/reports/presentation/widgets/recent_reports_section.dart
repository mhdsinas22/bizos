import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Data class representing a report generated during the session.
class RecentReportLog {
  final String id;
  final String reportType;
  final String businessName;
  final String dateRange;
  final DateTime generatedAt;

  const RecentReportLog({
    required this.id,
    required this.reportType,
    required this.businessName,
    required this.dateRange,
    required this.generatedAt,
  });
}

/// Recent Reports section matching the reference UI.
/// Shows a list of recently generated statements with timestamps, actions, and quick re-export.
class RecentReportsSection extends StatelessWidget {
  final List<RecentReportLog> recentReports;
  final ValueChanged<RecentReportLog>? onRePrint;
  final ValueChanged<RecentReportLog>? onReShare;
  final VoidCallback? onViewAll;

  const RecentReportsSection({
    super.key,
    required this.recentReports,
    this.onRePrint,
    this.onReShare,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          children: [
            // Squircle History Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.history_rounded, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Reports',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your recently generated reports.',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // View All Pill Button
            // Material(
            //   color: Colors.transparent,
            //   child: InkWell(
            //     onTap: onViewAll,
            //     borderRadius: BorderRadius.circular(20),
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 12,
            //         vertical: 6,
            //       ),
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(20),
            //         border: Border.all(
            //           color: borderColor,
            //           width: 1,
            //         ),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Text(
            //             'View All',
            //             style: TextStyle(
            //               fontSize: 12,
            //               fontWeight: FontWeight.w600,
            //               color: valueColor,
            //             ),
            //           ),
            //           const SizedBox(width: 4),
            //           Icon(
            //             Icons.chevron_right_rounded,
            //             size: 15,
            //             color: labelColor,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),

        const SizedBox(height: 14),

        // List of recent reports or empty prompt
        if (recentReports.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentReports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final report = recentReports[index];
              return _buildReportItemCard(
                context: context,
                report: report,
                isDark: isDark,
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161F30)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history_toggle_off_rounded,
                    size: 20,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No reports generated yet',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: valueColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Statements you generate above will appear here.',
                        style: TextStyle(fontSize: 11.5, color: labelColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReportItemCard({
    required BuildContext context,
    required RecentReportLog report,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF111728) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E283D)
        : const Color(0xFFE2E8F0);
    final labelColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final valueColor = isDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);

    final dateStr = DateFormat('dd MMM yyyy').format(report.generatedAt);
    final timeStr = DateFormat('hh:mm a').format(report.generatedAt);

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              // Squircle Document Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF162544)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_rounded,
                    size: 20,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reportType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${report.businessName} • ${report.dateRange}',
                      style: TextStyle(fontSize: 11.5, color: labelColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Timestamp Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              // More options menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 19,
                  color: labelColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (val) {
                  if (val == 'print') {
                    onRePrint?.call(report);
                  } else if (val == 'share') {
                    onReShare?.call(report);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Export & Print'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Share Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
