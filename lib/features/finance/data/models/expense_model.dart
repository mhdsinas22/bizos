class ExpenseModel {
  final String id;
  final String businessId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String? createdByUserId;
  final String? createdByName;

  ExpenseModel({
    required this.id,
    required this.businessId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.createdByUserId,
    this.createdByName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdByName': createdByName,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      createdByUserId: map['createdByUserId'] ?? map['created_by_user_id'],
      createdByName: map['createdByName'] ?? map['created_by_name'],
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? businessId,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? createdByUserId,
    String? createdByName,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}
