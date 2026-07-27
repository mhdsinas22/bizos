import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class TimelineBottomSheetWidget extends StatefulWidget {
  final MoneyTransactionHistoryEntity historyItem;
  final String transactionType;
  final Function(MoneyTransactionHistoryEntity updatedItem) onEdit;
  final VoidCallback onDelete;

  const TimelineBottomSheetWidget({
    super.key,
    required this.historyItem,
    required this.transactionType,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TimelineBottomSheetWidget> createState() => _TimelineBottomSheetWidgetState();
}

class _TimelineBottomSheetWidgetState extends State<TimelineBottomSheetWidget> {
  void _shareEvent() {
    final typeTitle = widget.historyItem.eventType.replaceAll('_', ' ').toUpperCase();
    final text = 'Event: $typeTitle\n'
        'Amount: ₹${widget.historyItem.amount.toStringAsFixed(2)}\n'
        'Method: ${widget.historyItem.paymentMethod ?? 'N/A'}\n'
        'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.historyItem.createdAt.toLocal())}\n'
        'Notes: ${widget.historyItem.notes}';
    Share.share(text);
  }

  void _showEditDialog() {
    final amountController = TextEditingController(text: widget.historyItem.amount.toString());
    final notesController = TextEditingController(text: widget.historyItem.notes);
    String method = widget.historyItem.paymentMethod ?? 'Cash';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit ${widget.historyItem.eventType.replaceAll('_', ' ').toUpperCase()}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.historyItem.eventType == 'payment' || widget.historyItem.eventType == 'adjustment')
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newAmount = double.tryParse(amountController.text) ?? widget.historyItem.amount;
                final updated = widget.historyItem.copyWith(
                  amount: newAmount,
                  notes: notesController.text.trim(),
                  paymentMethod: method,
                  eventType: widget.historyItem.eventType == 'payment' ? 'payment_updated' : widget.historyItem.eventType,
                );
                widget.onEdit(updated);
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Event?'),
          content: const Text(
            'Deleting this event will automatically recalculate the total debt, paid amount, and outstanding balance. Proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
                widget.onDelete();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.historyItem;
    final canEditOrDelete = item.eventType != 'debt_created';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.eventType.replaceAll('_', ' ').toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (item.amount > 0)
                Text(
                  CurrencyFormatter.format(item.amount),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: item.eventType == 'payment' ? AppTheme.success : AppTheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          if (item.paymentMethod != null && item.paymentMethod!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.payment, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Payment Method: ${item.paymentMethod}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Date: ${DateFormat('dd MMMM yyyy, hh:mm a').format(item.createdAt.toLocal())}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Notes: ${item.notes}', style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareEvent,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ),
              if (canEditOrDelete) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showEditDialog,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
