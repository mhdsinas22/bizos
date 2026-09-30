import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/presentation/bloc/category_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/category_event.dart';
import 'package:bizos/features/finance/presentation/bloc/category_state.dart';
import 'package:bizos/features/finance/presentation/widgets/add_category_bottom_sheet.dart';
import 'package:bizos/features/finance/presentation/widgets/manage_categories_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryDropdownField extends StatefulWidget {
  final String businessId;
  final String userId;
  final CategoryType type;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const CategoryDropdownField({
    super.key,
    required this.businessId,
    required this.userId,
    required this.type,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  State<CategoryDropdownField> createState() => _CategoryDropdownFieldState();
}

class _CategoryDropdownFieldState extends State<CategoryDropdownField> {
  static const String _addNewKey = '__ADD_NEW_CATEGORY__';
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    context.read<CategoryBloc>().add(
      FetchCategoriesEvent(businessId: widget.businessId, type: widget.type),
    );
  }

  @override
  void didUpdateWidget(covariant CategoryDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedValue = widget.initialValue;
      });
    }
  }

  void _openAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddCategoryBottomSheet(
        businessId: widget.businessId,
        userId: widget.userId,
        type: widget.type,
        onCategoryAdded: (newCat) {
          setState(() {
            _selectedValue = newCat.name;
          });
          widget.onChanged(newCat.name);
        },
      ),
    );
  }

  void _openManageCategoriesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ManageCategoriesBottomSheet(
        businessId: widget.businessId,
        userId: widget.userId,
        type: widget.type,
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

  Color? _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryLoaded && state.newlyAddedCategory != null) {
          if (state.type == widget.type) {
            setState(() {
              _selectedValue = state.newlyAddedCategory!.name;
            });
            widget.onChanged(state.newlyAddedCategory!.name);
          }
        }
      },
      builder: (context, state) {
        if (state is CategoryLoading && _selectedValue == null) {
          return Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading categories...'),
              ],
            ),
          );
        }

        List<CategoryEntity> categories = [];
        if (state is CategoryLoaded && state.type == widget.type) {
          categories = state.categories;
        } else if (state is CategoryAdding) {
          categories = state.currentCategories;
        } else if (state is CategoryError) {
          categories = state.currentCategories;
        }

        final categoryNames = categories.map((c) => c.name).toList();

        final items = <DropdownMenuItem<String>>[];

        if (_selectedValue != null &&
            _selectedValue!.isNotEmpty &&
            !categoryNames.contains(_selectedValue)) {
          items.add(
            DropdownMenuItem<String>(
              value: _selectedValue,
              child: Row(
                children: [
                  const Icon(Icons.history, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(_selectedValue!),
                ],
              ),
            ),
          );
        }

        for (final cat in categories) {
          final catColor = _hexToColor(cat.color);
          items.add(
            DropdownMenuItem<String>(
              value: cat.name,
              child: Row(
                children: [
                  Icon(
                    _getIconData(cat.icon),
                    size: 20,
                    color: catColor ?? theme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Text(cat.name),
                ],
              ),
            ),
          );
        }

        items.add(
          DropdownMenuItem<String>(
            value: _addNewKey,
            child: const Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 10),
                Text(
                  '+ Add New Category',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

        final validSelectedValue = items.any((i) => i.value == _selectedValue)
            ? _selectedValue
            : null;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: validSelectedValue,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'Select category',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: items,
                validator:
                    widget.validator ??
                    (val) {
                      if (val == null || val.isEmpty || val == _addNewKey) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                onChanged: (val) {
                  if (val == _addNewKey) {
                    _openAddCategorySheet();
                  } else if (val != null) {
                    setState(() {
                      _selectedValue = val;
                    });
                    widget.onChanged(val);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Manage Categories',
              child: InkWell(
                onTap: _openManageCategoriesSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  width: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
