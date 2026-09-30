import 'package:equatable/equatable.dart';

class InvoiceItemEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String? productServiceId;
  final String itemName;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discount;
  final double taxRate;
  final double taxAmount;
  final double lineTotal;

  const InvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    this.productServiceId,
    required this.itemName,
    this.description = '',
    this.quantity = 1.0,
    this.unit = 'item',
    required this.unitPrice,
    this.discount = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        productServiceId,
        itemName,
        description,
        quantity,
        unit,
        unitPrice,
        discount,
        taxRate,
        taxAmount,
        lineTotal,
      ];
}
