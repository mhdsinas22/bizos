import 'package:equatable/equatable.dart';

class MoneyTransactionEntity extends Equatable {
  final String id;
  final String? userId;
  final String? businessId;
  final String transactionType; // 'pay' or 'receive'
  final String personName;
  final String phone;
  final double amount;
  final double paidAmount;
  final double balanceAmount;
  final DateTime? dueDate;
  final String notes;
  final String status; // 'Pending' or 'Completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  const MoneyTransactionEntity({
    required this.id,
    this.userId,
    this.businessId,
    required this.transactionType,
    required this.personName,
    required this.phone,
    required this.amount,
    required this.paidAmount,
    required this.balanceAmount,
    this.dueDate,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  MoneyTransactionEntity copyWith({
    String? id,
    String? userId,
    String? businessId,
    String? transactionType,
    String? personName,
    String? phone,
    double? amount,
    double? paidAmount,
    double? balanceAmount,
    DateTime? dueDate,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoneyTransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      transactionType: transactionType ?? this.transactionType,
      personName: personName ?? this.personName,
      phone: phone ?? this.phone,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        businessId,
        transactionType,
        personName,
        phone,
        amount,
        paidAmount,
        balanceAmount,
        dueDate,
        notes,
        status,
        createdAt,
        updatedAt,
      ];
}
