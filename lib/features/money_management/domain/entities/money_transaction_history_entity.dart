import 'package:equatable/equatable.dart';

class MoneyTransactionHistoryEntity extends Equatable {
  final String id;
  final String transactionId;
  final String? userId;
  final String? businessId;
  final String eventType; // 'debt_created', 'payment', 'adjustment', 'reminder_sent', 'status_changed', 'payment_updated', 'payment_deleted'
  final double amount;
  final double balanceAfter;
  final String? paymentMethod; // 'Cash', 'GPay', 'PhonePe', 'Bank Transfer', 'UPI', 'Cheque', 'Other'
  final String notes;
  final String? createdBy;
  final DateTime createdAt;

  const MoneyTransactionHistoryEntity({
    required this.id,
    required this.transactionId,
    this.userId,
    this.businessId,
    required this.eventType,
    required this.amount,
    this.balanceAfter = 0.0,
    this.paymentMethod,
    required this.notes,
    this.createdBy,
    required this.createdAt,
  });

  MoneyTransactionHistoryEntity copyWith({
    String? id,
    String? transactionId,
    String? userId,
    String? businessId,
    String? eventType,
    double? amount,
    double? balanceAfter,
    String? paymentMethod,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return MoneyTransactionHistoryEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      eventType: eventType ?? this.eventType,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
        userId,
        businessId,
        eventType,
        amount,
        balanceAfter,
        paymentMethod,
        notes,
        createdBy,
        createdAt,
      ];
}
