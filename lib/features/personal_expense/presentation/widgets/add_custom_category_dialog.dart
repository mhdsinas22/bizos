import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddCustomCategoryDialog extends StatefulWidget {
  final String userId;
  final PersonalExpenseCategoryEntity? categoryToEdit;
  final Function(PersonalExpenseCategoryEntity)? onCategorySaved;

  const AddCustomCategoryDialog({
    super.key,
    required this.userId,
    this.categoryToEdit,
    this.onCategorySaved,
  });

  @override
  State<AddCustomCategoryDialog> createState() =>
      _AddCustomCategoryDialogState();
}

class _AddCustomCategoryDialogState extends State<AddCustomCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedIconName;
  String? _selectedColorHex;
  bool _isSaving = false;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final isEditing = widget.categoryToEdit != null;
    final category = PersonalExpenseCategoryEntity(
      id: isEditing ? widget.categoryToEdit!.id : '',
      ownerId: widget.userId,
      name: _nameController.text.trim(),
      icon: _selectedIconName,
      color: _selectedColorHex,
      isSystem: false,
      createdAt: isEditing
          ? widget.categoryToEdit!.createdAt
          : DateTime.now(),
    );

    if (isEditing) {
      context
          .read<PersonalExpenseCategoryBloc>()
          .add(UpdatePersonalCategoryEvent(category, widget.userId));
    } else {
      context
          .read<PersonalExpenseCategoryBloc>()
          .add(AddPersonalCategoryEvent(category, widget.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.categoryToEdit != null;
    final title = isEditing ? 'Edit Category' : 'Add Custom Category';

    return BlocListener<PersonalExpenseCategoryBloc, PersonalExpenseCategoryState>(
      listener: (context, state) {
        if (state is PersonalExpenseCategoryLoaded) {
          setState(() {
            _isSaving = false;
          });
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.success,
              ),
            );
          }
          if (state.newlyAddedCategory != null &&
              widget.onCategorySaved != null) {
            widget.onCategorySaved!(state.newlyAddedCategory!);
          }
          Navigator.pop(context);
        } else if (state is PersonalExpenseCategoryError) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Category Name *',
                    hint: 'e.g. Subscriptions, Hobbies',
                    prefixIcon: Icons.label_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Category name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Icon (Optional)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
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
                            size: 20,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Color (Optional)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
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
                          width: 34,
                          height: 34,
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
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          isSecondary: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: isEditing ? 'Update' : 'Save',
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveCategory,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
