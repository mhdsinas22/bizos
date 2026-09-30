import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/presentation/bloc/category_bloc.dart';
import 'package:bizos/features/finance/presentation/bloc/category_event.dart';
import 'package:bizos/features/finance/presentation/bloc/category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class CategoryFormSheet extends StatefulWidget {
  final String businessId;
  final String userId;
  final CategoryType type;
  final CategoryEntity? categoryToEdit;
  final Function(CategoryEntity)? onCategorySaved;

  const CategoryFormSheet({
    super.key,
    required this.businessId,
    required this.userId,
    required this.type,
    this.categoryToEdit,
    this.onCategorySaved,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedIconName;
  String? _selectedColorHex;

  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'local_offer', 'icon': Icons.local_offer},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
    {'name': 'receipt', 'icon': Icons.receipt_long},
    {'name': 'attach_money', 'icon': Icons.attach_money},
    {'name': 'store', 'icon': Icons.store},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'trending_up', 'icon': Icons.trending_up},
    {'name': 'business', 'icon': Icons.business},
    {'name': 'directions_car', 'icon': Icons.directions_car},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'electrical_services', 'icon': Icons.electrical_services},
    {'name': 'build', 'icon': Icons.build},
    {'name': 'computer', 'icon': Icons.computer},
    {'name': 'percent', 'icon': Icons.percent},
    {'name': 'groups', 'icon': Icons.groups},
  ];

  static const List<String> _availableColors = [
    '#4CAF50',
    '#2196F3',
    '#9C27B0',
    '#FF9800',
    '#E91E63',
    '#00BCD4',
    '#F44336',
    '#607D8B',
    '#795548',
    '#3F51B5',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.categoryToEdit?.name ?? '',
    );
    _selectedIconName = widget.categoryToEdit?.icon ?? 'local_offer';
    _selectedColorHex = widget.categoryToEdit?.color ?? '#4CAF50';
  }

  Color _hexToColor(String hex) {
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final isEditing = widget.categoryToEdit != null;
      final category = CategoryEntity(
        id: isEditing ? widget.categoryToEdit!.id : const Uuid().v4(),
        businessId: widget.businessId,
        name: _nameController.text.trim(),
        icon: _selectedIconName,
        color: _selectedColorHex,
        createdBy: isEditing ? widget.categoryToEdit!.createdBy : widget.userId,
        createdAt: isEditing ? widget.categoryToEdit!.createdAt : DateTime.now(),
        type: widget.type,
      );

      if (isEditing) {
        context.read<CategoryBloc>().add(UpdateCategoryEvent(category));
      } else {
        context.read<CategoryBloc>().add(AddCategoryEvent(category));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.categoryToEdit != null;
    final typeLabel = widget.type == CategoryType.income ? 'Income' : 'Expense';
    final title = isEditing
        ? 'Edit $typeLabel Category'
        : 'Add New $typeLabel Category';

    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: AppTheme.success,
            ),
          );
          if (state.newlyAddedCategory != null &&
              widget.onCategorySaved != null) {
            widget.onCategorySaved!(state.newlyAddedCategory!);
          }
          Navigator.pop(context);
        } else if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Category Name',
                  hint: 'e.g. Office Supplies, Consulting',
                  prefixIcon: Icons.label_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Icon',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableIcons.map((item) {
                    final iconName = item['name'] as String;
                    final iconData = item['icon'] as IconData;
                    final isSelected = _selectedIconName == iconName;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIconName = isSelected ? null : iconName;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor.withValues(alpha: 0.15)
                              : theme.cardColor,
                          border: Border.all(
                            color: isSelected
                                ? theme.primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.iconTheme.color,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Color',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableColors.map((colorHex) {
                    final color = _hexToColor(colorHex);
                    final isSelected = _selectedColorHex == colorHex;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColorHex = isSelected ? null : colorHex;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    final isLoading =
                        state is CategoryAdding || state is CategoryUpdating;
                    return CustomButton(
                      text: isEditing ? 'Update Category' : 'Save Category',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _saveCategory,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
