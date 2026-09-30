import 'package:equatable/equatable.dart';
import 'package:bizos/features/finance/presentation/widgets/payment_method_helper.dart';

class IncomeModel extends Equatable {
  final String id;
  final String businessId;
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final DateTime date;
  final String? createdByUserId;
  final String? createdByName;
  final DateTime? createdAt;

  const IncomeModel({
    required this.id,
    required this.businessId,
    required this.amount,
    required this.category,
    this.paymentMethod = 'Cash',
    required this.description,
    required this.date,
    this.createdByUserId,
    this.createdByName,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'paymentMethod': paymentMethod,
      'description': description,
      'date': date.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory IncomeModel.fromMap(Map<String, dynamic> map) {
    return IncomeModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? map['business_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'General',
      paymentMethod: PaymentMethodHelper.sanitize(
        map['payment_method'] ?? map['paymentMethod'],
      ),
      description: map['description'] ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date']).toLocal()
          : (map['income_date'] != null
              ? DateTime.parse(map['income_date']).toLocal()
              : DateTime.now()),
      createdByUserId: map['createdByUserId'] ?? map['created_by_user_id'],
      createdByName: map['createdByName'] ?? map['created_by_name'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt']).toLocal()
          : (map['created_at'] != null
              ? DateTime.parse(map['created_at']).toLocal()
              : null),
    );
  }

  factory IncomeModel.fromJson(Map<String, dynamic> json) =>
      IncomeModel.fromMap(json);

  IncomeModel copyWith({
    String? id,
    String? businessId,
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
    DateTime? date,
    String? createdByUserId,
    String? createdByName,
    DateTime? createdAt,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      date: date ?? this.date,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        amount,
        category,
        paymentMethod,
        description,
        date,
        createdByUserId,
        createdByName,
        createdAt,
      ];
}
