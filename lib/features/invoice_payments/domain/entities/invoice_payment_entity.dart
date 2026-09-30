import 'package:equatable/equatable.dart';

class InvoicePaymentEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String businessId;
  final String? incomeId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String notes;
  final String? createdByUserId;
  final DateTime createdAt;

  const InvoicePaymentEntity({
    required this.id,
    required this.invoiceId,
    required this.businessId,
    this.incomeId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = 'Cash',
    this.referenceNumber = '',
    this.notes = '',
    this.createdByUserId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        businessId,
        incomeId,
        amount,
        paymentDate,
        paymentMethod,
        referenceNumber,
        notes,
        createdByUserId,
        createdAt,
      ];
}
