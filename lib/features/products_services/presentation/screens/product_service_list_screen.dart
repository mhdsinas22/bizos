import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/core/widgets/skeleton_loader.dart';
import 'package:bizos/core/widgets/error_state.dart';
import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';
import 'package:bizos/features/products_services/presentation/bloc/product_service_bloc.dart';
import 'package:bizos/features/products_services/presentation/widgets/product_service_form_dialog.dart';

class ProductServiceListScreen extends StatefulWidget {
  final String businessId;
  final bool showAppBar;

  const ProductServiceListScreen({
    super.key,
    required this.businessId,
    this.showAppBar = true,
  });

  @override
  State<ProductServiceListScreen> createState() =>
      _ProductServiceListScreenState();
}

class _ProductServiceListScreenState extends State<ProductServiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final type = switch (_tabController.index) {
        0 => 'all',
        1 => 'service',
        2 => 'product',
        _ => 'all',
      };
      setState(() {
        _selectedType = type;
      });
      _fetchItems();
    });
    _fetchItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchItems() {
    context.read<ProductServiceBloc>().add(
      FetchProductsServicesEvent(
        businessId: widget.businessId,
        typeFilter: _selectedType,
        searchQuery: _searchController.text.trim(),
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchItems();
    });
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => ProductServiceFormDialog(businessId: widget.businessId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Products & Services'),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter Tabs & Add Button
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'All Items'),
                      Tab(text: 'Services'),
                      Tab(text: 'Products'),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products or services...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchItems();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurface
                    : AppTheme.lightSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // List Content
            Expanded(
              child: BlocConsumer<ProductServiceBloc, ProductServiceState>(
                listener: (context, state) {
                  if (state is ProductServiceActionSuccess) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  if (state is ProductServiceLoading &&
                      state is! ProductServiceLoaded) {
                    return const SkeletonListLoader(
                      itemCount: 6,
                      itemHeight: 72,
                    );
                  } else if (state is ProductServiceError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => _fetchItems(),
                    );
                  } else if (state is ProductServiceLoaded) {
                    final items = state.items;
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No Products or Services',
                        message: _searchController.text.isNotEmpty
                            ? 'No items match your search.'
                            : 'Create generic products or services for your business.',
                        actionLabel: 'Add Product/Service',
                        onActionPressed: _openAddDialog,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _fetchItems(),
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, e) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildItemTile(context, item);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, ProductServiceEntity item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isService = item.isService;

    return GlassCard(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isService ? Colors.blue : Colors.purple).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isService ? Icons.build_outlined : Icons.inventory_2_outlined,
            color: isService ? Colors.blue : Colors.purple,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration: item.isActive ? null : TextDecoration.lineThrough,
                  color: item.isActive
                      ? null
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
            Chip(
              visualDensity: VisualDensity.compact,
              labelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              label: Text(item.type.toUpperCase()),
              backgroundColor: (isService ? Colors.blue : Colors.purple)
                  .withValues(alpha: 0.12),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  ' / ${item.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                if (item.taxRate > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${item.taxRate}% Tax)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.isActive,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (val) {
                context.read<ProductServiceBloc>().add(
                  ToggleProductServiceActiveEvent(
                    itemId: item.id,
                    isActive: val,
                    businessId: widget.businessId,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ProductServiceFormDialog(
                    businessId: widget.businessId,
                    item: item,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
                size: 20,
              ),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context, item),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductServiceEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ProductServiceBloc>().add(
                DeleteProductServiceEvent(
                  itemId: item.id,
                  businessId: widget.businessId,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
