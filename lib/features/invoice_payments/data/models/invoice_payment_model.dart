import 'package:bizos/features/invoice_payments/domain/entities/invoice_payment_entity.dart';

class InvoicePaymentModel extends InvoicePaymentEntity {
  const InvoicePaymentModel({
    required super.id,
    required super.invoiceId,
    required super.businessId,
    super.incomeId,
    required super.amount,
    required super.paymentDate,
    super.paymentMethod = 'Cash',
    super.referenceNumber = '',
    super.notes = '',
    super.createdByUserId,
    required super.createdAt,
  });

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentModel(
      id: json['id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      incomeId: json['income_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String).toLocal()
          : DateTime.now(),
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      referenceNumber: json['reference_number'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdByUserId: json['created_by'] as String? ?? json['created_by_user_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
    };
    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }
    if (createdByUserId != null && createdByUserId!.isNotEmpty) {
      map['created_by'] = createdByUserId;
    }
    return map;
  }

  InvoicePaymentModel copyWith({
    String? id,
    String? invoiceId,
    String? businessId,
    String? incomeId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
    String? createdByUserId,
    DateTime? createdAt,
  }) {
    return InvoicePaymentModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      businessId: businessId ?? this.businessId,
      incomeId: incomeId ?? this.incomeId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory InvoicePaymentModel.fromEntity(InvoicePaymentEntity entity) {
    return InvoicePaymentModel(
      id: entity.id,
      invoiceId: entity.invoiceId,
      businessId: entity.businessId,
      incomeId: entity.incomeId,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      paymentMethod: entity.paymentMethod,
      referenceNumber: entity.referenceNumber,
      notes: entity.notes,
      createdByUserId: entity.createdByUserId,
      createdAt: entity.createdAt,
    );
  }
}
