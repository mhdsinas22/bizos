import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_state.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/add_custom_category_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManagePersonalCategoriesSheet extends StatefulWidget {
  final String userId;

  const ManagePersonalCategoriesSheet({
    super.key,
    required this.userId,
  });

  @override
  State<ManagePersonalCategoriesSheet> createState() =>
      _ManagePersonalCategoriesSheetState();
}

class _ManagePersonalCategoriesSheetState
    extends State<ManagePersonalCategoriesSheet> {
  @override
  void initState() {
    super.initState();
    context
        .read<PersonalExpenseCategoryBloc>()
        .add(LoadPersonalCategoriesEvent(widget.userId));
  }

  void _openAddCategoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddCustomCategoryDialog(
        userId: widget.userId,
      ),
    );
  }

  void _openEditCategoryDialog(PersonalExpenseCategoryEntity category) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AddCustomCategoryDialog(
        userId: widget.userId,
        categoryToEdit: category,
      ),
    );
  }

  void _confirmDeleteCategory(PersonalExpenseCategoryEntity category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PersonalExpenseCategoryBloc>().add(
                    DeletePersonalCategoryEvent(category, widget.userId),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName, String categoryName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'receipt':
        return Icons.receipt_long;
      case 'attach_money':
        return Icons.attach_money;
      case 'store':
        return Icons.store;
      case 'work':
        return Icons.work;
      case 'trending_up':
        return Icons.trending_up;
      case 'business':
        return Icons.business;
      case 'directions_car':
        return Icons.directions_car;
      case 'restaurant':
        return Icons.restaurant;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'build':
        return Icons.build;
      case 'computer':
        return Icons.computer;
      case 'percent':
        return Icons.percent;
      case 'groups':
        return Icons.groups;
      case 'local_offer':
      default:
        break;
    }

    switch (categoryName.toLowerCase()) {
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
        return Icons.category_outlined;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primaryColor;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: BlocConsumer<PersonalExpenseCategoryBloc,
          PersonalExpenseCategoryState>(
        listener: (context, state) {
          if (state is PersonalExpenseCategoryLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.success,
              ),
            );
          } else if (state is PersonalExpenseCategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          List<PersonalExpenseCategoryEntity> categories = [];
          if (state is PersonalExpenseCategoryLoaded) {
            categories = state.categories;
          } else if (state is PersonalExpenseCategoryError) {
            categories = state.currentCategories;
          }

          final isLoading = state is PersonalExpenseCategoryLoading;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Categories',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Add Category Action Button
              ElevatedButton.icon(
                onPressed: _openAddCategoryDialog,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Add Custom Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category List
              Flexible(
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final catColor = _hexToColor(cat.color);

                          return GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(
                                        alpha: isDark ? 0.25 : 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: catColor.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Icon(
                                    _getIconData(cat.icon, cat.name),
                                    color: catColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (cat.isSystem)
                                        Text(
                                          'System Category',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.disabledColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Show Edit & Delete buttons ONLY if isSystem == false
                                if (!cat.isSystem) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    color: theme.colorScheme.primary,
                                    tooltip: 'Edit Category',
                                    onPressed: () =>
                                        _openEditCategoryDialog(cat),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                    color: AppTheme.error,
                                    tooltip: 'Delete Category',
                                    onPressed: () =>
                                        _confirmDeleteCategory(cat),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
