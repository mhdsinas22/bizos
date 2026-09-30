import 'package:equatable/equatable.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';

class InvoiceEntity extends Equatable {
  final String id;
  final String businessId;
  final String? customerId;
  final String customerNameSnapshot;
  final String customerPhoneSnapshot;
  final String customerEmailSnapshot;
  final String customerAddressSnapshot;
  final String customerGstinSnapshot;
  final String invoiceNumber;
  final int sequenceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String status; // 'draft', 'sent', 'partially_paid', 'paid', 'overdue', 'cancelled'
  final String paymentStatus; // 'unpaid', 'partially_paid', 'paid'
  final double subtotal;
  final String discountType; // 'percentage', 'flat'
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String notes;
  final String paymentInstructions;
  final Map<String, dynamic>? templateSnapshot;
  final String? createdByUserId;
  final String? createdByName;
  final List<InvoiceItemEntity> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceEntity({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.customerNameSnapshot,
    this.customerPhoneSnapshot = '',
    this.customerEmailSnapshot = '',
    this.customerAddressSnapshot = '',
    this.customerGstinSnapshot = '',
    required this.invoiceNumber,
    this.sequenceNumber = 1,
    required this.invoiceDate,
    this.dueDate,
    this.status = 'draft',
    this.paymentStatus = 'unpaid',
    this.subtotal = 0.0,
    this.discountType = 'flat',
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.grandTotal = 0.0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    this.notes = '',
    this.paymentInstructions = '',
    this.templateSnapshot,
    this.createdByUserId,
    this.createdByName,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isPaid => status.toLowerCase() == 'paid' || paymentStatus.toLowerCase() == 'paid';
  bool get isPartiallyPaid => status.toLowerCase() == 'partially_paid' || paymentStatus.toLowerCase() == 'partially_paid';
  bool get isUnpaid => paymentStatus.toLowerCase() == 'unpaid';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isOverdue => status.toLowerCase() == 'overdue';

  @override
  List<Object?> get props => [
        id,
        businessId,
        customerId,
        customerNameSnapshot,
        customerPhoneSnapshot,
        customerEmailSnapshot,
        customerAddressSnapshot,
        customerGstinSnapshot,
        invoiceNumber,
        sequenceNumber,
        invoiceDate,
        dueDate,
        status,
        paymentStatus,
        subtotal,
        discountType,
        discountAmount,
        taxAmount,
        grandTotal,
        paidAmount,
        balanceAmount,
        notes,
        paymentInstructions,
        templateSnapshot,
        createdByUserId,
        createdByName,
        items,
        createdAt,
        updatedAt,
      ];
}
