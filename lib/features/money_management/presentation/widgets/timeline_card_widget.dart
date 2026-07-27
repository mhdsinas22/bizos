import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineCardWidget extends StatelessWidget {
  final MoneyTransactionHistoryEntity historyItem;
  final String transactionType; // 'pay' or 'receive'
  final VoidCallback onTap;

  const TimelineCardWidget({
    super.key,
    required this.historyItem,
    required this.transactionType,
    required this.onTap,
  });

  IconData _getEventIcon() {
    switch (historyItem.eventType) {
      case 'debt_created':
        return Icons.note_add_outlined;
      case 'payment':
      case 'payment_updated':
        return Icons.payments_outlined;
      case 'adjustment':
        return Icons.tune_outlined;
      case 'reminder_sent':
        return Icons.notifications_active_outlined;
      case 'status_changed':
        return Icons.published_with_changes_outlined;
      default:
        return Icons.history;
    }
  }

  String _getEventTitle() {
    switch (historyItem.eventType) {
      case 'debt_created':
        return 'Debt Created';
      case 'payment':
        return transactionType == 'pay' ? 'Payment Made' : 'Payment Received';
      case 'payment_updated':
        return 'Payment Updated';
      case 'payment_deleted':
        return 'Payment Removed';
      case 'adjustment':
        return 'Balance Adjustment';
      case 'reminder_sent':
        return 'Payment Reminder Sent';
      case 'status_changed':
        return 'Status Changed';
      default:
        return historyItem.eventType.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getEventColor(BuildContext context) {
    switch (historyItem.eventType) {
      case 'payment':
      case 'payment_updated':
        return AppTheme.success;
      case 'debt_created':
      case 'adjustment':
        return AppTheme.error;
      case 'reminder_sent':
        return Colors.orange;
      case 'status_changed':
        return AppTheme.primaryColor;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getEventColor(context);
    final isPayment = historyItem.eventType == 'payment' || historyItem.eventType == 'payment_updated';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        border: BorderSide(color: color.withOpacity(0.2), width: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Icon Avatar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_getEventIcon(), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _getEventTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (historyItem.amount > 0 || isPayment)
                        Text(
                          '${isPayment ? '+' : ''}${CurrencyFormatter.format(historyItem.amount)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isPayment ? AppTheme.success : AppTheme.error,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (historyItem.paymentMethod != null && historyItem.paymentMethod!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withOpacity(0.25), width: 0.8),
                          ),
                          child: Text(
                            historyItem.paymentMethod!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        DateFormat('hh:mm a').format(historyItem.createdAt.toLocal()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  if (historyItem.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      historyItem.notes,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                  if (historyItem.createdBy != null && historyItem.createdBy!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'By: ${historyItem.createdBy}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
