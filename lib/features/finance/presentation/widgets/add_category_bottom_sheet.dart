import 'package:bizos/features/finance/domain/entities/category_entity.dart';
import 'package:bizos/features/finance/presentation/widgets/category_form_sheet.dart';
import 'package:flutter/material.dart';

class AddCategoryBottomSheet extends StatelessWidget {
  final String businessId;
  final String userId;
  final CategoryType type;
  final Function(CategoryEntity) onCategoryAdded;

  const AddCategoryBottomSheet({
    super.key,
    required this.businessId,
    required this.userId,
    required this.type,
    required this.onCategoryAdded,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryFormSheet(
      businessId: businessId,
      userId: userId,
      type: type,
      onCategorySaved: onCategoryAdded,
    );
  }
}
