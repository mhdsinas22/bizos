import 'package:bizos/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String password;

  UserModel({
    super.id = '',
    super.name = '',
    super.email = '',
    super.phone = '',
    super.role = '',
    super.ownerId = '',
    String? userid,
    String? userId,
    this.password = '',
    List<String>? permissions,
    List<String>? customPermissions,
    super.businessPermissions = const {},
  }) : super(
         userid: userid ?? userId ?? '',
         customPermissions: customPermissions ?? permissions ?? const [],
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> custPerms = [];
    if (json['permissions'] != null) {
      custPerms = List<String>.from(json['permissions'] as Iterable);
    } else if (json['customPermissions'] != null) {
      custPerms = List<String>.from(json['customPermissions'] as Iterable);
    }

    Map<String, List<String>> bizPerms = {};
    if (json['businessPermissions'] != null) {
      final map = json['businessPermissions'] as Map;
      map.forEach((k, v) {
        bizPerms[k.toString()] = List<String>.from(v as Iterable);
      });
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      userid: json['userid']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      customPermissions: custPerms,
      businessPermissions: bizPerms,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'userid': userid,
      'owner_id': ownerId,
      'password': password,
      'customPermissions': customPermissions,
      'businessPermissions': businessPermissions,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? userid,
    String? userId,
    String? ownerId,
    String? password,
    List<String>? customPermissions,
    Map<String, List<String>>? businessPermissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      userid: userid ?? this.userid,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      password: password ?? this.password,
      customPermissions: customPermissions ?? this.customPermissions,
      businessPermissions: businessPermissions ?? this.businessPermissions,
    );
  }
}
