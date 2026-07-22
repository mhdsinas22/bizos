import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/activity/domain/entities/activity_entity.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActivityCard extends StatelessWidget {
  final ActivityEntity activity;
  final String? businessName;

  const ActivityCard({
    super.key,
    required this.activity,
    this.businessName,
  });

  bool get _isEdit =>
      activity.action.toLowerCase().contains('update') ||
      activity.action.toLowerCase().contains('edit');

  bool get _isDelete =>
      activity.action.toLowerCase().contains('delete') ||
      activity.action.toLowerCase().contains('remove');

  /// Dynamic Color System based on Module and Action
  Color _getActionColor() {
    final module = activity.module.toLowerCase();

    if (_isDelete) {
      if (module == 'expense') return const Color(0xFFDC2626); // Dark Red
      return const Color(0xFFEF4444); // Standard Red
    }

    if (_isEdit) {
      switch (module) {
        case 'income':
          return const Color(0xFF3B82F6); // Blue
        case 'expense':
          return const Color(0xFF6366F1); // Indigo
        case 'money':
          return const Color(0xFF06B6D4); // Cyan
        case 'task':
          return const Color(0xFF3B82F6); // Blue
        default:
          return const Color(0xFF8B5CF6); // Purple
      }
    }

    // Add / Create
    switch (module) {
      case 'income':
        return const Color(0xFF22C55E); // Green
      case 'expense':
        return const Color(0xFFF59E0B); // Amber / Orange
      case 'money':
        return const Color(0xFF10B981); // Emerald
      case 'task':
        return const Color(0xFF10B981); // Emerald
      case 'staff':
        return const Color(0xFF14B8A6); // Teal
      default:
        return const Color(0xFF10B981); // Emerald
    }
  }

  /// Primary Module Icon
  IconData _getModuleIcon() {
    switch (activity.module.toLowerCase()) {
      case 'income':
        return Icons.payments_outlined;
      case 'expense':
        return Icons.receipt_long_outlined;
      case 'money':
        return Icons.account_balance_wallet_outlined;
      case 'task':
        return Icons.task_alt_outlined;
      case 'staff':
        return Icons.person_outline;
      case 'business':
        return Icons.storefront_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  /// Action Badge Icon
  IconData _getActionIcon() {
    if (_isDelete) return Icons.delete_outline;
    if (_isEdit) return Icons.edit_outlined;
    return Icons.add_circle_outline;
  }

  /// Action Status Label
  String get _statusLabel {
    if (_isDelete) return 'Deleted';
    if (_isEdit) return 'Updated';
    return 'Added';
  }

  double? _extractAmount() {
    try {
      final regExp = RegExp(r'Amount:\s*([0-9.]+)');
      final match = regExp.firstMatch(activity.description);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    } catch (_) {}
    return null;
  }

  String _cleanDescription() {
    String desc = activity.description
        .replaceAll(RegExp(r'\|\s*Amount:\s*[0-9.]+'), '')
        .replaceAll(RegExp(r'\|\s*Phone:\s*[^\s|]+'), '')
        .replaceAll(RegExp(r'\|\s*Balance:\s*[0-9.]+'), '')
        .trim();
    if (desc.startsWith('|')) desc = desc.substring(1).trim();
    if (desc.endsWith('|')) desc = desc.substring(0, desc.length - 1).trim();
    return desc.isEmpty ? activity.title : desc;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionColor = _getActionColor();
    final moduleIcon = _getModuleIcon();
    final actionIcon = _getActionIcon();
    final amount = _extractAmount();
    final cleanDesc = _cleanDescription();

    final timeString = DateFormat.jm().format(activity.createdAt);
    final dateString = DateFormat.yMMMd().format(activity.createdAt);

    final showAmount = amount != null;
    final isIncome = activity.module.toLowerCase() == 'income';
    final isExpense = activity.module.toLowerCase() == 'expense';

    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.user;

    String displayUserName = activity.createdBy;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (currentUser != null) {
      if (activity.createdBy == currentUser.id ||
          activity.createdBy == currentUser.userId ||
          activity.createdBy.isEmpty ||
          uuidRegex.hasMatch(activity.createdBy)) {
        displayUserName = currentUser.name.isNotEmpty
            ? currentUser.name
            : (currentUser.userid.isNotEmpty ? currentUser.userid : 'You');
      }
    } else if (uuidRegex.hasMatch(displayUserName)) {
      displayUserName = 'User';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : actionColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: actionColor,
                width: 4.5,
              ),
            ),
          ),
          child: GlassCard(
            borderRadius: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: _isDelete
                ? actionColor.withValues(alpha: isDark ? 0.08 : 0.04)
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Module Icon with Action Indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: actionColor.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: actionColor.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        moduleIcon,
                        color: actionColor,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: actionColor, width: 1.2),
                        ),
                        child: Icon(
                          actionIcon,
                          color: actionColor,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _isDelete
                                    ? actionColor
                                    : (isDark ? Colors.white : Colors.black87),
                                decoration: _isDelete
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: actionColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: actionColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _statusLabel.toUpperCase(),
                              style: TextStyle(
                                color: actionColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cleanDesc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (businessName != null) ...[
                            const Icon(
                              Icons.storefront_outlined,
                              size: 11,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                businessName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          const Icon(
                            Icons.person_outline,
                            size: 11,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayUserName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Trailing section (Amount & Time)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showAmount)
                      Text(
                        '${isIncome ? '+' : isExpense ? '-' : ''}${CurrencyFormatter.format(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: _isDelete
                              ? actionColor
                              : isIncome
                                  ? const Color(0xFF22C55E)
                                  : isExpense
                                      ? const Color(0xFFEF4444)
                                      : actionColor,
                          decoration: _isDelete
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: actionColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
