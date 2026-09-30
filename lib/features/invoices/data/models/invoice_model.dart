import 'package:bizos/features/invoices/data/models/invoice_item_model.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.businessId,
    super.customerId,
    required super.customerNameSnapshot,
    super.customerPhoneSnapshot = '',
    super.customerEmailSnapshot = '',
    super.customerAddressSnapshot = '',
    super.customerGstinSnapshot = '',
    required super.invoiceNumber,
    super.sequenceNumber = 1,
    required super.invoiceDate,
    super.dueDate,
    super.status = 'draft',
    super.paymentStatus = 'unpaid',
    super.subtotal = 0.0,
    super.discountType = 'flat',
    super.discountAmount = 0.0,
    super.taxAmount = 0.0,
    super.grandTotal = 0.0,
    super.paidAmount = 0.0,
    super.balanceAmount = 0.0,
    super.notes = '',
    super.paymentInstructions = '',
    super.templateSnapshot,
    super.createdByUserId,
    super.createdByName,
    super.items = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    List<InvoiceItemModel> itemList = [];
    if (json['invoice_items'] != null) {
      itemList = (json['invoice_items'] as List<dynamic>)
          .map((item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final customerData = json['customers'] is Map ? (json['customers'] as Map<String, dynamic>) : null;

    return InvoiceModel(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      customerId: json['customer_id'] as String?,
      customerNameSnapshot: customerData?['name'] as String? ?? json['customer_name_snapshot'] as String? ?? '',
      customerPhoneSnapshot: customerData?['phone'] as String? ?? json['customer_phone_snapshot'] as String? ?? '',
      customerEmailSnapshot: customerData?['email'] as String? ?? json['customer_email_snapshot'] as String? ?? '',
      customerAddressSnapshot: customerData?['address'] as String? ?? json['customer_address_snapshot'] as String? ?? '',
      customerGstinSnapshot: customerData?['gstin'] as String? ?? json['customer_gstin_snapshot'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      sequenceNumber: (json['sequence_number'] as num?)?.toInt() ?? 1,
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String).toLocal()
          : DateTime.now(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'draft',
      paymentStatus: json['payment_status'] as String? ?? json['status'] as String? ?? 'unpaid',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'flat',
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['total_amount'] as num?)?.toDouble() ?? (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      paymentInstructions: json['payment_instructions'] as String? ?? '',
      templateSnapshot: json['template_snapshot'] is Map
          ? Map<String, dynamic>.from(json['template_snapshot'] as Map)
          : null,
      createdByUserId: json['created_by'] as String? ?? json['created_by_user_id'] as String?,
      createdByName: json['created_by_name'] as String?,
      items: itemList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'business_id': businessId,
      'customer_id': (customerId != null && customerId!.isNotEmpty) ? customerId : null,
      'invoice_number': invoiceNumber,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': grandTotal,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'status': status,
      'notes': notes,
      'payment_instructions': paymentInstructions,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }
    if (dueDate != null) {
      map['due_date'] = dueDate!.toIso8601String().split('T')[0];
    }
    if (createdByUserId != null && createdByUserId!.isNotEmpty) {
      map['created_by'] = createdByUserId;
    }
    return map;
  }

  InvoiceModel copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerNameSnapshot,
    String? customerPhoneSnapshot,
    String? customerEmailSnapshot,
    String? customerAddressSnapshot,
    String? customerGstinSnapshot,
    String? invoiceNumber,
    int? sequenceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? status,
    String? paymentStatus,
    double? subtotal,
    String? discountType,
    double? discountAmount,
    double? taxAmount,
    double? grandTotal,
    double? paidAmount,
    double? balanceAmount,
    String? notes,
    String? paymentInstructions,
    Map<String, dynamic>? templateSnapshot,
    String? createdByUserId,
    String? createdByName,
    List<InvoiceItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerNameSnapshot: customerNameSnapshot ?? this.customerNameSnapshot,
      customerPhoneSnapshot: customerPhoneSnapshot ?? this.customerPhoneSnapshot,
      customerEmailSnapshot: customerEmailSnapshot ?? this.customerEmailSnapshot,
      customerAddressSnapshot: customerAddressSnapshot ?? this.customerAddressSnapshot,
      customerGstinSnapshot: customerGstinSnapshot ?? this.customerGstinSnapshot,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      notes: notes ?? this.notes,
      paymentInstructions: paymentInstructions ?? this.paymentInstructions,
      templateSnapshot: templateSnapshot ?? this.templateSnapshot,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InvoiceModel.fromEntity(InvoiceEntity entity) {
    return InvoiceModel(
      id: entity.id,
      businessId: entity.businessId,
      customerId: entity.customerId,
      customerNameSnapshot: entity.customerNameSnapshot,
      customerPhoneSnapshot: entity.customerPhoneSnapshot,
      customerEmailSnapshot: entity.customerEmailSnapshot,
      customerAddressSnapshot: entity.customerAddressSnapshot,
      customerGstinSnapshot: entity.customerGstinSnapshot,
      invoiceNumber: entity.invoiceNumber,
      sequenceNumber: entity.sequenceNumber,
      invoiceDate: entity.invoiceDate,
      dueDate: entity.dueDate,
      status: entity.status,
      paymentStatus: entity.paymentStatus,
      subtotal: entity.subtotal,
      discountType: entity.discountType,
      discountAmount: entity.discountAmount,
      taxAmount: entity.taxAmount,
      grandTotal: entity.grandTotal,
      paidAmount: entity.paidAmount,
      balanceAmount: entity.balanceAmount,
      notes: entity.notes,
      paymentInstructions: entity.paymentInstructions,
      templateSnapshot: entity.templateSnapshot,
      createdByUserId: entity.createdByUserId,
      createdByName: entity.createdByName,
      items: entity.items.map((i) => InvoiceItemModel.fromEntity(i)).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
