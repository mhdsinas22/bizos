import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required super.id,
    required super.invoiceId,
    super.productServiceId,
    required super.itemName,
    super.description = '',
    super.quantity = 1.0,
    super.unit = 'item',
    required super.unitPrice,
    super.discount = 0.0,
    super.taxRate = 0.0,
    super.taxAmount = 0.0,
    required super.lineTotal,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String? ?? '',
      productServiceId: json['product_service_id'] as String?,
      itemName: json['item_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'item',
      unitPrice: (json['rate'] as num?)?.toDouble() ?? (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount_amount'] as num?)?.toDouble() ?? (json['discount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson({String? parentInvoiceId}) {
    final map = <String, dynamic>{
      'invoice_id': parentInvoiceId ?? invoiceId,
      'product_service_id': (productServiceId != null && productServiceId!.isNotEmpty) ? productServiceId : null,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': unitPrice,
      'discount_amount': discount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'line_total': lineTotal,
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  factory InvoiceItemModel.fromEntity(InvoiceItemEntity entity) {
    return InvoiceItemModel(
      id: entity.id,
      invoiceId: entity.invoiceId,
      productServiceId: entity.productServiceId,
      itemName: entity.itemName,
      description: entity.description,
      quantity: entity.quantity,
      unit: entity.unit,
      unitPrice: entity.unitPrice,
      discount: entity.discount,
      taxRate: entity.taxRate,
      taxAmount: entity.taxAmount,
      lineTotal: entity.lineTotal,
    );
  }
}
