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
      if (_selectedType != type) {
        setState(() {
          _selectedType = type;
        });
        _fetchItems();
      }
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Search Bar & Add Item Button Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search products or services...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
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
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _openAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Tabs (Full width, sleek segmented pills, zero clipping)
            Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface
                    : const Color(0xFFF1F5F9), // Slate 100
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? Colors.white60 : const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'All Items'),
                  Tab(text: 'Services'),
                  Tab(text: 'Products'),
                ],
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
                      itemHeight: 90,
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
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: items.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isService = item.isService;
    final accentColor = isService ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => ProductServiceFormDialog(
            businessId: widget.businessId,
            item: item,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // TOP ROW: Icon + Title & Badges + Status Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: item.isActive ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: item.isActive ? 0.25 : 0.12),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isService ? Icons.build_rounded : Icons.inventory_2_rounded,
                  color: item.isActive ? accentColor : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Badges, and Description Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Name takes all available horizontal space!
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                              decoration: item.isActive ? null : TextDecoration.lineThrough,
                              color: item.isActive
                                  ? null
                                  : (isDark ? Colors.white38 : Colors.black38),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Type Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Subtle Hairline Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),

          const SizedBox(height: 10),

          // BOTTOM ROW: Price & Tax (Left) + Actions (Right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price, Unit, and Tax Badge
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '/ ${item.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    if (item.taxRate > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${item.taxRate}% Tax',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Action Buttons Row (Switch + Edit + Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active Toggle Switch
                  Tooltip(
                    message: item.isActive
                        ? 'Active (tap to disable)'
                        : 'Inactive (tap to enable)',
                    child: SizedBox(
                      height: 28,
                      width: 44,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch(
                          value: item.isActive,
                          activeThumbColor: AppTheme.primaryColor,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Edit Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

                  // Delete Button
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.error,
                      size: 18,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductServiceEntity item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Item', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ProductServiceBloc>().add(
                DeleteProductServiceEvent(
                  itemId: item.id,
                  businessId: widget.businessId,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
