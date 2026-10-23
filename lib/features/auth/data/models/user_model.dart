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
    super.authUserId = '',
    String? userid,
    String? userId,
    this.password = '',
    List<String>? permissions,
    List<String>? customPermissions,
    super.businessPermissions = const {},
    super.currencyCode = 'INR',
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

    final rawCurrency = json['currency_code'] ?? json['currencyCode'];
    final currencyCode =
        (rawCurrency != null && rawCurrency.toString().trim().isNotEmpty)
        ? rawCurrency.toString().trim().toUpperCase()
        : 'INR';

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      userid: json['userid']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      authUserId: json['auth_user_id']?.toString() ?? "",
      password: json['password']?.toString() ?? '',
      customPermissions: custPerms,
      businessPermissions: bizPerms,
      currencyCode: currencyCode,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  /// Serializes the user model.
  ///
  /// CRITICAL SECURITY REQUIREMENT: [includePassword] defaults to false to prevent
  /// plaintext passwords from ever being written to SharedPreferences or local cache.
  Map<String, dynamic> toJson({bool includePassword = false}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'userid': userid,
      'owner_id': ownerId,
      'auth_user_id': authUserId,
      'customPermissions': customPermissions,
      'businessPermissions': businessPermissions,
      'currency_code': currencyCode,
    };
    if (includePassword && password.isNotEmpty) {
      map['password'] = password;
    }
    return map;
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
    String? authUserId,
    String? password,
    List<String>? customPermissions,
    Map<String, List<String>>? businessPermissions,
    String? currencyCode,
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
      authUserId: authUserId ?? this.authUserId,
      password: password ?? this.password,
      customPermissions: customPermissions ?? this.customPermissions,
      businessPermissions: businessPermissions ?? this.businessPermissions,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
