import 'package:equatable/equatable.dart';

class DebtEntity extends Equatable {
  final String? id;
  final String? transactionId; // Target existing active transaction ID if available
  final String? userId;
  final String? businessId;
  final String transactionType; // 'pay' or 'receive'
  final String personName;
  final String phone;
  final double amount;
  final double paidAmount;
  final double balanceAmount;
  final DateTime dueDate;
  final String notes;
  final String status; // 'Pending' or 'Partial'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const DebtEntity({
    this.id,
    this.transactionId,
    this.userId,
    this.businessId,
    required this.transactionType,
    required this.personName,
    required this.phone,
    required this.amount,
    this.paidAmount = 0.0,
    required this.balanceAmount,
    required this.dueDate,
    required this.notes,
    this.status = 'Pending',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  DebtEntity copyWith({
    String? id,
    String? transactionId,
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
    String? createdBy,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
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
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        transactionId,
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
        createdBy,
      ];
}
