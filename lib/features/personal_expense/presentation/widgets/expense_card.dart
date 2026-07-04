import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bizos/core/utils/currency_formatter.dart';

class ExpenseCard extends StatelessWidget {
  final PersonalExpenseEntity expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'travel':
        return Icons.commute;
      case 'fuel':
        return Icons.local_gas_station;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'family':
        return Icons.people_outline;
      case 'education':
        return Icons.school_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'bills':
        return Icons.receipt_outlined;
      case 'investment':
        return Icons.trending_up_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'travel':
        return AppTheme.info;
      case 'fuel':
        return Colors.amber.shade700;
      case 'shopping':
        return Colors.pink;
      case 'medical':
        return AppTheme.error;
      case 'family':
        return Colors.teal;
      case 'education':
        return AppTheme.primaryColor;
      case 'entertainment':
        return Colors.deepPurple;
      case 'bills':
        return Colors.blueGrey;
      case 'investment':
        return Colors.green;
      default:
        final hash = category.hashCode;
        final colors = [
          Colors.deepOrange,
          Colors.lightGreen,
          Colors.lime,
          Colors.indigo,
          Colors.brown,
          Colors.cyan,
        ];
        return colors[hash.abs() % colors.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(expense.category);
    final formattedAmount = CurrencyFormatter.format(expense.amount);
    final formattedDate = DateFormat.yMMMd().format(expense.expenseDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        expense.category,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formattedAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          expense.description.isNotEmpty
                              ? expense.description
                              : 'No description provided',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: expense.description.isNotEmpty
                                ? theme.textTheme.bodyMedium?.color
                                : theme.disabledColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              onPressed: onEdit,
              tooltip: 'Edit Expense',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
                size: 20,
              ),
              onPressed: () => _confirmDelete(context),
              tooltip: 'Delete Expense',
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to permanently delete this personal expense record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
