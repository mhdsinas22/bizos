import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';

class MoneyTransactionModel extends MoneyTransactionEntity {
  const MoneyTransactionModel({
    required super.id,
    super.userId,
    super.businessId,
    required super.transactionType,
    required super.personName,
    required super.phone,
    required super.amount,
    required super.paidAmount,
    required super.balanceAmount,
    super.dueDate,
    required super.notes,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MoneyTransactionModel.fromJson(Map<String, dynamic> json) {
    return MoneyTransactionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      businessId: json['business_id'] as String?,
      transactionType: json['transaction_type'] as String? ?? 'pay',
      personName: json['person_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'transaction_type': transactionType,
      'person_name': personName,
      'phone': phone,
      'amount': amount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'notes': notes,
      'status': status,
    };

    if (id.isNotEmpty) {
      data['id'] = id;
    }
    if (userId != null) {
      data['user_id'] = userId;
    }
    if (businessId != null) {
      data['business_id'] = businessId;
    }
    if (dueDate != null) {
      data['due_date'] = dueDate!.toIso8601String();
    }
    return data;
  }

  factory MoneyTransactionModel.fromEntity(MoneyTransactionEntity entity) {
    return MoneyTransactionModel(
      id: entity.id,
      userId: entity.userId,
      businessId: entity.businessId,
      transactionType: entity.transactionType,
      personName: entity.personName,
      phone: entity.phone,
      amount: entity.amount,
      paidAmount: entity.paidAmount,
      balanceAmount: entity.balanceAmount,
      dueDate: entity.dueDate,
      notes: entity.notes,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
