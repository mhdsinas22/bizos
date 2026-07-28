import 'package:bizos/features/money_management/domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    super.id,
    super.transactionId,
    super.userId,
    super.businessId,
    required super.transactionType,
    required super.personName,
    required super.phone,
    required super.amount,
    super.paidAmount = 0.0,
    required super.balanceAmount,
    required super.dueDate,
    required super.notes,
    super.status = 'Pending',
    required super.createdAt,
    required super.updatedAt,
    super.createdBy,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String?,
      transactionId: json['transaction_id'] as String?,
      userId: json['user_id'] as String?,
      businessId: json['business_id'] as String?,
      transactionType: json['transaction_type'] as String? ?? 'pay',
      personName: json['person_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balance_amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toTransactionJson({bool isPersonal = false}) {
    final data = <String, dynamic>{
      'transaction_type': transactionType,
      'person_name': personName,
      'phone': phone,
      'amount': amount,
      'paid_amount': 0.0,
      'balance_amount': amount,
      'due_date': dueDate.toUtc().toIso8601String(),
      'notes': notes,
      'status': 'Pending',
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };

    if (id != null && id!.isNotEmpty) {
      data['id'] = id;
    }
    if (isPersonal) {
      if (userId != null && userId!.isNotEmpty) {
        data['user_id'] = userId;
      }
    } else {
      if (businessId != null && businessId!.isNotEmpty) {
        data['business_id'] = businessId;
      }
    }
    return data;
  }

  Map<String, dynamic> toHistoryJson({
    required String parentTransactionId,
    required String eventType, // 'debt_added' or 'debt_created'
    required double balanceAfter,
    bool isPersonal = false,
  }) {
    final data = <String, dynamic>{
      'transaction_id': parentTransactionId,
      'event_type': eventType,
      'payment_method': null,
      'amount': amount,
      'balance_after': balanceAfter,
      'notes': notes.isNotEmpty
          ? notes
          : (eventType == 'debt_added' ? 'Debt Added' : 'Debt Created'),
      'created_at': createdAt.toUtc().toIso8601String(),
    };

    if (createdBy != null && createdBy!.isNotEmpty) {
      data['created_by'] = createdBy;
    }
    if (isPersonal) {
      if (userId != null && userId!.isNotEmpty) {
        data['user_id'] = userId;
      }
    } else {
      if (businessId != null && businessId!.isNotEmpty) {
        data['business_id'] = businessId;
      }
    }
    return data;
  }

  factory DebtModel.fromEntity(DebtEntity entity) {
    return DebtModel(
      id: entity.id,
      transactionId: entity.transactionId,
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
      createdBy: entity.createdBy,
    );
  }
}
