class BusinessModel {
  final String id;
  final String name;
  final String type;
  final String phone;
  final String address;
  final String notes;
  final String ownerId;

  BusinessModel({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.address,
    required this.notes,
    required this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'address': address,
      'notes': notes,
      'ownerId': ownerId,
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    return BusinessModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      ownerId: map['ownerId'] ?? '',
    );
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    String? type,
    String? phone,
    String? address,
    String? notes,
    String? ownerId,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
