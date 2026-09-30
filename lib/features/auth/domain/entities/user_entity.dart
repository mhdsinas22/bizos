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
        return perms.contains(permission) || perms.contains('all');
      }
      return false; // Unassigned business has no permissions
    }
    return customPermissions.contains(permission);
  }

  bool canViewInvoices({String? businessId}) =>
      hasPermission('view_invoices', businessId: businessId) ||
      hasPermission('view_accounts', businessId: businessId);

  bool canCreateInvoices({String? businessId}) =>
      hasPermission('create_invoices', businessId: businessId) ||
      hasPermission('view_accounts', businessId: businessId);

  bool canEditInvoices({String? businessId}) =>
      hasPermission('edit_invoices', businessId: businessId) ||
      hasPermission('view_accounts', businessId: businessId);

  bool canDeleteInvoices({String? businessId}) =>
      isOwner || hasPermission('delete_invoices', businessId: businessId);

  bool canManageCustomers({String? businessId}) =>
      hasPermission('manage_customers', businessId: businessId) ||
      hasPermission('view_accounts', businessId: businessId);

  bool canManageProducts({String? businessId}) =>
      hasPermission('manage_products', businessId: businessId) ||
      hasPermission('view_accounts', businessId: businessId);

  bool canManagePayments({String? businessId}) =>
      hasPermission('manage_payments', businessId: businessId) ||
      hasPermission('view_accounts', businessId: businessId);

  bool canManageInvoiceSettings({String? businessId}) =>
      isOwner || hasPermission('manage_invoice_settings', businessId: businessId);
}
