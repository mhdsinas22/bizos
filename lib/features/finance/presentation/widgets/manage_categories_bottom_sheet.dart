import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/responsive_breakpoints.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/presentation/bloc/category_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/category_event.dart';
import 'package:bizos/features/finance/presentation/bloc/category_state.dart';
import 'package:bizos/features/finance/presentation/widgets/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageCategoriesBottomSheet extends StatefulWidget {
  final String businessId;
  final String userId;
  final CategoryType type;

  const ManageCategoriesBottomSheet({
    super.key,
    required this.businessId,
    required this.userId,
    required this.type,
  });

  @override
  State<ManageCategoriesBottomSheet> createState() =>
      _ManageCategoriesBottomSheetState();
}

class _ManageCategoriesBottomSheetState
    extends State<ManageCategoriesBottomSheet> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(
          FetchCategoriesEvent(
            businessId: widget.businessId,
            type: widget.type,
          ),
        );
  }

  void _openAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CategoryFormSheet(
        businessId: widget.businessId,
        userId: widget.userId,
        type: widget.type,
      ),
    );
  }

  void _openEditCategorySheet(CategoryEntity category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CategoryFormSheet(
        businessId: widget.businessId,
        userId: widget.userId,
        type: widget.type,
        categoryToEdit: category,
      ),
    );
  }

  void _confirmDeleteCategory(CategoryEntity category) {
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
              context.read<CategoryBloc>().add(
                    DeleteCategoryEvent(
                      id: category.id,
                      type: category.type,
                      businessId: widget.businessId,
                      categoryName: category.name,
                    ),
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

  IconData _getIconData(String? iconName) {
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
        return Icons.local_offer;
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
    final typeLabel =
        widget.type == CategoryType.income ? 'Income' : 'Expense';

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
      child: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          List<CategoryEntity> categories = [];
          if (state is CategoryLoaded && state.type == widget.type) {
            categories = state.categories;
          } else if (state is CategoryAdding) {
            categories = state.currentCategories;
          } else if (state is CategoryUpdating) {
            categories = state.currentCategories;
          } else if (state is CategoryDeleting) {
            categories = state.currentCategories;
          } else if (state is CategoryError) {
            categories = state.currentCategories;
          }

          final isLoading = state is CategoryLoading;
          final isOperating = state is CategoryAdding ||
              state is CategoryUpdating ||
              state is CategoryDeleting;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveBreakpoints.maxFormWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Drag handle pill
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
                      'Manage $typeLabel Categories',
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
                  onPressed: isOperating ? null : _openAddCategorySheet,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: Text('Add New $typeLabel Category'),
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

                if (isOperating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),

                // Category List
                Flexible(
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: SkeletonListLoader(
                              itemCount: 4, itemHeight: 64),
                        )
                      : categories.isEmpty
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 32.0),
                              child: EmptyState(
                                icon: Icons.category_outlined,
                                title: 'No Categories Available',
                                message:
                                    'Create custom $typeLabel categories to organize your transactions.',
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
                                            color:
                                                catColor.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Icon(
                                          _getIconData(cat.icon),
                                          color: catColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          cat.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 20),
                                        color: theme.colorScheme.primary,
                                        tooltip: 'Edit Category',
                                        onPressed: isOperating
                                            ? null
                                            : () => _openEditCategorySheet(cat),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        color: AppTheme.error,
                                        tooltip: 'Delete Category',
                                        onPressed: isOperating
                                            ? null
                                            : () =>
                                                _confirmDeleteCategory(cat),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}
