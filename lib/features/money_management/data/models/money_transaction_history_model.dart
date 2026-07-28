import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';

class MoneyTransactionHistoryModel extends MoneyTransactionHistoryEntity {
  const MoneyTransactionHistoryModel({
    required super.id,
    required super.transactionId,
    super.userId,
    super.businessId,
    required super.eventType,
    required super.amount,
    super.balanceAfter,
    super.paymentMethod,
    required super.notes,
    super.createdBy,
    required super.createdAt,
  });

  factory MoneyTransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return MoneyTransactionHistoryModel(
      id: json['id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      businessId: json['business_id'] as String?,
      eventType: json['event_type'] as String? ?? 'payment',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String? ?? '',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  static String sanitizeEventType(String type) {
    switch (type) {
      case 'debt_created':
      case 'receivable_created':
        return 'debt_created';
      case 'debt_added':
      case 'receivable_added':
        return 'debt_added';
      case 'payment':
      case 'payment_updated':
      case 'collection_received':
        return 'payment';
      case 'adjustment':
        return 'adjustment';
      case 'reminder_sent':
        return 'reminder_sent';
      case 'status_changed':
        return 'status_changed';
      default:
        return 'payment';
    }
  }

  Map<String, dynamic> toJson({bool isPersonal = false}) {
    final data = <String, dynamic>{
      'transaction_id': transactionId,
      'event_type': sanitizeEventType(eventType),
      'amount': amount,
      'balance_after': balanceAfter,
      'notes': notes,
    };

    if (id.isNotEmpty) {
      data['id'] = id;
    }
    if (isPersonal) {
      if (userId != null) {
        data['user_id'] = userId;
      }
    } else {
      if (businessId != null) {
        data['business_id'] = businessId;
      }
    }
    if (paymentMethod != null && paymentMethod!.isNotEmpty) {
      data['payment_method'] = paymentMethod;
    }
    if (createdBy != null && createdBy!.isNotEmpty) {
      data['created_by'] = createdBy;
    }
    data['created_at'] = createdAt.toUtc().toIso8601String();

    return data;
  }

  factory MoneyTransactionHistoryModel.fromEntity(MoneyTransactionHistoryEntity entity) {
    return MoneyTransactionHistoryModel(
      id: entity.id,
      transactionId: entity.transactionId,
      userId: entity.userId,
      businessId: entity.businessId,
      eventType: entity.eventType,
      amount: entity.amount,
      balanceAfter: entity.balanceAfter,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
    );
  }
}
