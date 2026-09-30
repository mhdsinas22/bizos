import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String gstin;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.gstin = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        phone,
        email,
        address,
        gstin,
        notes,
        createdAt,
        updatedAt,
      ];
}
