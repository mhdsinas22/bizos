import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/core/widgets/glass_card.dart';
import 'package:bizos/features/customers/domain/entities/customer_entity.dart';
import 'package:bizos/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:bizos/features/customers/presentation/widgets/customer_form_dialog.dart';
import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';
import 'package:bizos/features/products_services/presentation/bloc/product_service_bloc.dart';
import 'package:bizos/features/invoice_settings/domain/entities/invoice_settings_entity.dart';
import 'package:bizos/features/invoice_settings/presentation/bloc/invoice_settings_bloc.dart';
import 'package:bizos/features/invoice_settings/presentation/widgets/invoice_live_preview_widget.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';
import 'package:bizos/features/invoices/presentation/bloc/invoice_bloc.dart';

class InvoiceCreateEditScreen extends StatefulWidget {
  final String businessId;
  final InvoiceEntity? invoice;

  const InvoiceCreateEditScreen({
    super.key,
    required this.businessId,
    this.invoice,
  });

  @override
  State<InvoiceCreateEditScreen> createState() =>
      _InvoiceCreateEditScreenState();
}

class _InvoiceCreateEditScreenState extends State<InvoiceCreateEditScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerEntity? _selectedCustomer;
  late TextEditingController _invoiceNumberController;
  DateTime _invoiceDate = DateTime.now();
  DateTime? _dueDate;

  final List<InvoiceItemEntity> _selectedItems = [];
  String _discountType = 'flat';
  double _discountAmount = 0.0;
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _paymentInstructionsController =
      TextEditingController();
  final TextEditingController _initialPaymentController = TextEditingController(
    text: '0',
  );

  String _status = 'sent';

  @override
  void initState() {
    super.initState();
    _invoiceNumberController = TextEditingController();

    // Fetch dependencies
    context.read<CustomerBloc>().add(
      FetchCustomersEvent(businessId: widget.businessId),
    );
    context.read<ProductServiceBloc>().add(
      FetchProductsServicesEvent(
        businessId: widget.businessId,
        activeOnly: true,
      ),
    );
    context.read<InvoiceSettingsBloc>().add(
      FetchInvoiceSettingsEvent(widget.businessId),
    );

    if (widget.invoice != null) {
      _populateFields(widget.invoice!);
    } else {
      context.read<InvoiceBloc>().add(
        GenerateNextInvoiceNumberEvent(businessId: widget.businessId),
      );
      _dueDate = DateTime.now().add(const Duration(days: 15));
    }
  }

  void _populateFields(InvoiceEntity inv) {
    _invoiceNumberController.text = inv.invoiceNumber;
    _invoiceDate = inv.invoiceDate;
    _dueDate = inv.dueDate;
    _status = inv.status;
    _discountType = inv.discountType;
    _discountAmount = inv.discountAmount;
    _discountController.text = inv.discountAmount.toString();
    _notesController.text = inv.notes;
    _paymentInstructionsController.text = inv.paymentInstructions;
    _initialPaymentController.text = inv.paidAmount.toString();
    _selectedItems.addAll(inv.items);

    _selectedCustomer = CustomerEntity(
      id: inv.customerId ?? '',
      businessId: inv.businessId,
      name: inv.customerNameSnapshot,
      phone: inv.customerPhoneSnapshot,
      email: inv.customerEmailSnapshot,
      address: inv.customerAddressSnapshot,
      gstin: inv.customerGstinSnapshot,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _paymentInstructionsController.dispose();
    _initialPaymentController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
  }

  double get _taxAmount {
    return _selectedItems.fold(0.0, (sum, item) {
      final lineSub = item.quantity * item.unitPrice;
      return sum + (lineSub * (item.taxRate / 100));
    });
  }

  double get _computedDiscount {
    if (_discountType == 'percentage') {
      return _subtotal * (_discountAmount / 100);
    }
    return _discountAmount;
  }

  double get _grandTotal {
    final total = (_subtotal - _computedDiscount) + _taxAmount;
    return total > 0 ? total : 0.0;
  }

  void _addItemFromCatalog(ProductServiceEntity catalogItem) {
    final lineSub = catalogItem.price * 1;
    final lineTax = lineSub * (catalogItem.taxRate / 100);
    final lineTotal = lineSub + lineTax;

    setState(() {
      _selectedItems.add(
        InvoiceItemEntity(
          id: '',
          invoiceId: widget.invoice?.id ?? '',
          productServiceId: catalogItem.id,
          itemName: catalogItem.name,
          description: catalogItem.description,
          quantity: 1,
          unit: catalogItem.unit,
          unitPrice: catalogItem.price,
          taxRate: catalogItem.taxRate,
          taxAmount: lineTax,
          lineTotal: lineTotal,
        ),
      );
    });
  }

  void _submitInvoice() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a customer first.'),
        ),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the invoice.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final initialPaid =
        double.tryParse(_initialPaymentController.text.trim()) ?? 0.0;
    final balance = (_grandTotal - initialPaid) > 0
        ? (_grandTotal - initialPaid)
        : 0.0;
    final payStatus = balance <= 0
        ? 'paid'
        : (initialPaid > 0 ? 'partially_paid' : 'unpaid');
    final finalStatus = _status == 'draft'
        ? 'draft'
        : (balance <= 0 ? 'paid' : _status);

    final isEdit = widget.invoice != null;

    final invoice = InvoiceEntity(
      id: isEdit ? widget.invoice!.id : '',
      businessId: widget.businessId,
      customerId: _selectedCustomer!.id.isNotEmpty
          ? _selectedCustomer!.id
          : null,
      customerNameSnapshot: _selectedCustomer!.name,
      customerPhoneSnapshot: _selectedCustomer!.phone,
      customerEmailSnapshot: _selectedCustomer!.email,
      customerAddressSnapshot: _selectedCustomer!.address,
      customerGstinSnapshot: _selectedCustomer!.gstin,
      invoiceNumber: _invoiceNumberController.text.trim(),
      invoiceDate: _invoiceDate,
      dueDate: _dueDate,
      status: finalStatus,
      paymentStatus: payStatus,
      subtotal: _subtotal,
      discountType: _discountType,
      discountAmount: _discountAmount,
      taxAmount: _taxAmount,
      grandTotal: _grandTotal,
      paidAmount: initialPaid,
      balanceAmount: balance,
      notes: _notesController.text.trim(),
      paymentInstructions: _paymentInstructionsController.text.trim(),
      createdAt: isEdit ? widget.invoice!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (isEdit) {
      context.read<InvoiceBloc>().add(
        UpdateInvoiceEvent(invoice: invoice, items: _selectedItems),
      );
    } else {
      context.read<InvoiceBloc>().add(
        CreateInvoiceEvent(invoice: invoice, items: _selectedItems),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.invoice != null;

    return BlocListener<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state is NextInvoiceNumberGenerated && !isEdit) {
          _invoiceNumberController.text = state.invoiceNumber;
        } else if (state is InvoiceActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Invoice' : 'Create New Invoice'),
          actions: [
            TextButton.icon(
              onPressed: _submitInvoice,
              icon: const Icon(Icons.check, color: AppTheme.primaryColor),
              label: Text(
                isEdit ? 'Save Changes' : 'Issue Invoice',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 950;
            final formWidget = _buildEditorForm(context, isDark);

            if (isWide) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(child: formWidget),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child:
                          BlocBuilder<
                            InvoiceSettingsBloc,
                            InvoiceSettingsState
                          >(
                            builder: (context, settingsState) {
                              InvoiceSettingsEntity settings =
                                  InvoiceSettingsEntity(
                                    id: '',
                                    businessId: widget.businessId,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                              if (settingsState is InvoiceSettingsLoaded) {
                                settings = settingsState.settings;
                              }
                              return SingleChildScrollView(
                                child: InvoiceLivePreviewWidget(
                                  settings: settings,
                                  sampleCustomerName: _selectedCustomer?.name,
                                  sampleTotal: _grandTotal,
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: formWidget,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorForm(BuildContext context, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Select Customer & Invoice Number
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '1. Customer & Metadata',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              CustomerFormDialog(businessId: widget.businessId),
                        );
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('New Customer'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    List<CustomerEntity> customers = [];
                    if (state is CustomerLoaded) {
                      customers = state.customers;
                    }

                    final displayCustomers = List<CustomerEntity>.from(
                      customers,
                    );
                    if (_selectedCustomer != null &&
                        !displayCustomers.any(
                          (c) => c.id == _selectedCustomer!.id,
                        )) {
                      displayCustomers.insert(0, _selectedCustomer!);
                    }

                    CustomerEntity? selectedVal;
                    if (_selectedCustomer != null) {
                      final matchIndex = displayCustomers.indexWhere(
                        (c) => c.id == _selectedCustomer!.id,
                      );
                      if (matchIndex != -1) {
                        selectedVal = displayCustomers[matchIndex];
                      }
                    }

                    return DropdownButtonFormField<CustomerEntity>(
                      initialValue: selectedVal,
                      decoration: InputDecoration(
                        labelText: 'Select Customer *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: displayCustomers.map((c) {
                        return DropdownMenuItem<CustomerEntity>(
                          value: c,
                          child: Text(
                            '${c.name} ${c.phone.isNotEmpty ? "(${c.phone})" : ""}',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomer = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _invoiceNumberController,
                        decoration: InputDecoration(
                          labelText: 'Invoice Number *',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Invoice Date',
                          style: TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 18),
                        onTap: () async {
                          final p = await showDatePicker(
                            context: context,
                            initialDate: _invoiceDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (p != null) setState(() => _invoiceDate = p);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Step 2: Add Line Items
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2. Products & Services',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    PopupMenuButton<ProductServiceEntity>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: AppTheme.primaryColor,
                      ),
                      tooltip: 'Add Item from Catalog',
                      itemBuilder: (context) {
                        final state = context.read<ProductServiceBloc>().state;
                        List<ProductServiceEntity> items = [];
                        if (state is ProductServiceLoaded) {
                          items = state.items;
                        }
                        if (items.isEmpty) {
                          return [
                            const PopupMenuItem(
                              enabled: false,
                              child: Text('No catalog items available'),
                            ),
                          ];
                        }
                        return items.map((item) {
                          return PopupMenuItem(
                            value: item,
                            child: Row(
                              children: [
                                Icon(
                                  item.isService
                                      ? Icons.build_outlined
                                      : Icons.inventory_2_outlined,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.name} (${CurrencyFormatter.format(item.price)})',
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      onSelected: _addItemFromCatalog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_selectedItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No items added yet. Click "+ Add Item from Catalog" above.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedItems.length,
                    separatorBuilder: (_, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _selectedItems[index];
                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${item.unitPrice} / ${item.unit}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      setState(() {
                                        final newQty = item.quantity - 1;
                                        final newSub = newQty * item.unitPrice;
                                        final newTax =
                                            newSub * (item.taxRate / 100);
                                        _selectedItems[index] =
                                            InvoiceItemEntity(
                                              id: item.id,
                                              invoiceId: item.invoiceId,
                                              productServiceId:
                                                  item.productServiceId,
                                              itemName: item.itemName,
                                              description: item.description,
                                              quantity: newQty,
                                              unit: item.unit,
                                              unitPrice: item.unitPrice,
                                              taxRate: item.taxRate,
                                              taxAmount: newTax,
                                              lineTotal: newSub + newTax,
                                            );
                                      });
                                    }
                                  },
                                ),
                                Text(
                                  '${item.quantity.toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      final newQty = item.quantity + 1;
                                      final newSub = newQty * item.unitPrice;
                                      final newTax =
                                          newSub * (item.taxRate / 100);
                                      _selectedItems[index] = InvoiceItemEntity(
                                        id: item.id,
                                        invoiceId: item.invoiceId,
                                        productServiceId: item.productServiceId,
                                        itemName: item.itemName,
                                        description: item.description,
                                        quantity: newQty,
                                        unit: item.unit,
                                        unitPrice: item.unitPrice,
                                        taxRate: item.taxRate,
                                        taxAmount: newTax,
                                        lineTotal: newSub + newTax,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedItems.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Step 3: Totals & Initial Payment Calculation
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3. Summary & Payment Terms',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(
                      CurrencyFormatter.format(_subtotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax Amount:'),
                    Text(
                      CurrencyFormatter.format(_taxAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _discountAmount =
                                double.tryParse(val.trim()) ?? 0.0;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Discount Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _discountType,
                      items: const [
                        DropdownMenuItem(
                          value: 'flat',
                          child: Text('Flat (₹)'),
                        ),
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Percent (%)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _discountType = val);
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _initialPaymentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Optional Initial Payment Received (₹)',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submit Action
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.send_outlined),
              label: Text(
                widget.invoice != null
                    ? 'Update Invoice'
                    : 'Create & Issue Invoice',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
