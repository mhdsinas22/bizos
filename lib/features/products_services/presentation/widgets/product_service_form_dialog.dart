import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';
import 'package:bizos/features/products_services/presentation/bloc/product_service_bloc.dart';

class ProductServiceFormDialog extends StatefulWidget {
  final String businessId;
  final ProductServiceEntity? item;

  const ProductServiceFormDialog({
    super.key,
    required this.businessId,
    this.item,
  });

  @override
  State<ProductServiceFormDialog> createState() => _ProductServiceFormDialogState();
}

class _ProductServiceFormDialogState extends State<ProductServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _taxRateController;
  late TextEditingController _unitController;
  String _selectedType = 'service';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item != null ? widget.item!.price.toString() : '');
    _taxRateController = TextEditingController(text: widget.item != null ? widget.item!.taxRate.toString() : '0');
    _unitController = TextEditingController(text: widget.item?.unit ?? 'item');
    _selectedType = widget.item?.type ?? 'service';
    _isActive = widget.item?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _taxRateController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.item != null;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final taxRate = double.tryParse(_taxRateController.text.trim()) ?? 0.0;

    final item = ProductServiceEntity(
      id: isEdit ? widget.item!.id : '',
      businessId: widget.businessId,
      name: _nameController.text.trim(),
      type: _selectedType,
      description: _descriptionController.text.trim(),
      price: price,
      taxRate: taxRate,
      unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'item',
      isActive: _isActive,
      createdAt: isEdit ? widget.item!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      context.read<ProductServiceBloc>().add(UpdateProductServiceEvent(item));
    } else {
      context.read<ProductServiceBloc>().add(AddProductServiceEvent(item));
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        isEdit ? 'Edit Product/Service' : 'Add Product or Service',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Selector
                const Text(
                  'Item Type *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'service',
                      label: Text('Service'),
                      icon: Icon(Icons.build_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'product',
                      label: Text('Product'),
                      icon: Icon(Icons.inventory_2_outlined, size: 16),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedType = set.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Shirt Cleaning, Screen Repair, iPhone 15',
                    prefixIcon: const Icon(Icons.label_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price (₹) *',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Price is required';
                          }
                          if (double.tryParse(val.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          hintText: 'pcs, hrs, kg',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _taxRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tax Rate (%)',
                    prefixIcon: const Icon(Icons.percent_outlined),
                    hintText: 'e.g. 18',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                SwitchListTile(
                  title: const Text('Active Status', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _isActive ? 'Available for new invoices' : 'Hidden from new invoices',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  value: _isActive,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(isEdit ? 'Save Changes' : 'Add Item'),
        ),
      ],
    );
  }
}
