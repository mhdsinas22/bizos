import 'package:bizos/core/theme/app_theme.dart';
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
import 'package:intl/intl.dart';

class CategoryManagementScreen extends StatefulWidget {
  final String businessId;
  final String userId;

  const CategoryManagementScreen({
    super.key,
    required this.businessId,
    required this.userId,
  });

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchCategoriesForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _fetchCategoriesForCurrentTab();
  }

  CategoryType get _currentType => _tabController.index == 0
      ? CategoryType.income
      : CategoryType.expense;

  void _fetchCategoriesForCurrentTab() {
    context.read<CategoryBloc>().add(
          FetchCategoriesEvent(
            businessId: widget.businessId,
            type: _currentType,
          ),
        );
  }

  void _openCategoryForm({CategoryEntity? categoryToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CategoryFormSheet(
        businessId: widget.businessId,
        userId: widget.userId,
        type: _currentType,
        categoryToEdit: categoryToEdit,
      ),
    );
  }

  void _confirmDeleteCategory(CategoryEntity category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          tabs: const [
            Tab(
              icon: Icon(Icons.arrow_upward, size: 18),
              text: 'Income Categories',
            ),
            Tab(
              icon: Icon(Icons.arrow_downward, size: 18),
              text: 'Expense Categories',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCategoryForm(),
        icon: const Icon(Icons.add),
        label: Text('Add ${_currentType == CategoryType.income ? 'Income' : 'Expense'} Category'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.success,
              ),
            );
          } else if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: SkeletonListLoader(itemCount: 5, itemHeight: 80),
            );
          }

          List<CategoryEntity> categories = [];
          if (state is CategoryLoaded && state.type == _currentType) {
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

          if (categories.isEmpty && state is! CategoryLoading) {
            return RefreshIndicator(
              onRefresh: () async => _fetchCategoriesForCurrentTab(),
              child: ListView(
                children: [
                  const SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.category_outlined,
                    title: 'No Categories Found',
                    message:
                        'Create your custom ${_currentType == CategoryType.income ? 'income' : 'expense'} categories to organize transactions.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _fetchCategoriesForCurrentTab(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final catColor = _hexToColor(cat.color);
                final createdDateStr = cat.createdAt != null
                    ? DateFormat('dd MMM yyyy').format(cat.createdAt!.toLocal())
                    : 'System Default';

                return GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          _getIconData(cat.icon),
                          color: catColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cat.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: catColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Created: $createdDateStr',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openCategoryForm(categoryToEdit: cat);
                          } else if (value == 'delete') {
                            _confirmDeleteCategory(cat);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppTheme.error),
                                SizedBox(width: 10),
                                Text('Delete',
                                    style: TextStyle(color: AppTheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
