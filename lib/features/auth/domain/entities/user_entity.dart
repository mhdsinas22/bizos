class UserEntity {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String userid;
  final String ownerId;
  final List<String> customPermissions;
  final Map<String, List<String>> businessPermissions;

  UserEntity({
    this.id = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.role = '',
    this.userid = '',
    this.ownerId = '',
    this.customPermissions = const [],
    this.businessPermissions = const {},
  });

  String get userId => userid;

  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isStaff => role.toLowerCase() == 'staff';
  bool get isAdmin => role.toLowerCase() == 'admin';

  List<String> get permissions {
    if (isOwner) {
      return const ['view_tasks', 'add_tasks', 'view_accounts'];
    }
    return customPermissions;
  }

  bool hasPermission(String permission, {String? businessId}) {
    if (isOwner) return true;
    if (businessId != null) {
      final perms = businessPermissions[businessId];
      if (perms != null) {
        return perms.contains(permission);
      }
    }
    return customPermissions.contains(permission);
  }
}
