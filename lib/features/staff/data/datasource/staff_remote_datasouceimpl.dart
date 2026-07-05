import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/data/datasource/staff_remote_datasource.dart';
import 'package:bizos/features/staff/data/models/staff_business_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StaffRemoteDatasourceImpl implements StaffRemoteDatasource {
  final SupabaseClient supabaseClient;

  StaffRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<UserModel>> getStaffList(String ownerId) async {
    print("ownerId:-$ownerId");
    final response = await supabaseClient
        .from('users')
        .select()
        .eq('role', 'Staff')
        .eq('owner_id', ownerId);

    final staffList = <UserModel>[];

    for (var row in response) {
      final userUuid = row['id'] as String;

      // Query permissions for this user
      final permsResponse = await supabaseClient
          .from('staff_permissions')
          .select()
          .eq('user_id', userUuid);

      final bizPerms = <String, List<String>>{};
      final flatPerms = <String>{};

      for (var permRow in permsResponse) {
        final bizId = permRow['business_id'] as String;
        final perms = <String>[];
        if (permRow['can_view_tasks'] == true) perms.add('view_tasks');
        if (permRow['can_add_tasks'] == true) perms.add('add_tasks');
        if (permRow['can_view_accounts'] == true) perms.add('view_accounts');

        bizPerms[bizId] = perms;
        flatPerms.addAll(perms);
      }

      final userMap = Map<String, dynamic>.from(row);
      userMap['permissions'] = flatPerms.toList();
      userMap['businessPermissions'] = bizPerms;

      staffList.add(UserModel.fromJson(userMap));
    }

    return staffList;
  }

  @override
  Future<void> createStaff(
    UserModel staff,
    String ownerId,
    List<String> selectedBusinessIds,
  ) async {
    // Check if userid already exists
    final existing = await supabaseClient
        .from('users')
        .select()
        .eq('userid', staff.userId.trim().toLowerCase())
        .maybeSingle();

    if (existing != null) {
      throw Exception('User ID "${staff.userId}" is already taken.');
    }

    final uuid = const Uuid().v4();
    final email = '${staff.userId.trim().toLowerCase()}@bizos.local';

    // 1. Insert user
    try {
      await supabaseClient.from('users').insert({
        'id': uuid,
        'name': staff.name,
        'email': email,
        'phone': '',
        'role': 'Staff',
        'userid': staff.userId.trim().toLowerCase(),
        'password': staff.password,
        "owner_id": ownerId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('User ID "${staff.userId}" is already taken.');
      }
      rethrow;
    }

    // 2. Insert into staff_businesses
    if (selectedBusinessIds.isNotEmpty) {
      final staffBizInserts = selectedBusinessIds
          .map(
            (bId) => {
              'staff_id': uuid,
              'business_id': bId,
              'created_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();
      await supabaseClient.from('staff_businesses').insert(staffBizInserts);
    }

    // 3. Grant permissions for all businesses owned by this owner
    if (selectedBusinessIds.isNotEmpty) {
      final viewTasks =
          staff.customPermissions.contains('view_tasks') ||
          staff.permissions.contains('view_tasks');
      final addTasks =
          staff.customPermissions.contains('add_tasks') ||
          staff.permissions.contains('add_tasks');
      final viewAccounts =
          staff.customPermissions.contains('view_accounts') ||
          staff.permissions.contains('view_accounts');

      final permInserts = selectedBusinessIds
          .map(
            (b) => {
              'id': const Uuid().v4(),
              'user_id': uuid,
              'business_id': b,
              'can_view_tasks': viewTasks,
              'can_add_tasks': addTasks,
              'can_view_accounts': viewAccounts,
            },
          )
          .toList();

      await supabaseClient.from('staff_permissions').insert(permInserts);
    }
  }

  @override
  Future<void> updateStaff(UserModel staff, List<String> selectedBusinessIds) async {
    // 1. Resolve user UUID by username/userid
    final userResponse = await supabaseClient
        .from('users')
        .select('id')
        .eq('userid', staff.userId.trim().toLowerCase())
        .maybeSingle();

    if (userResponse == null) {
      throw Exception('Staff member not found.');
    }

    final String userUuid = userResponse['id'] as String;

    // 2. Update user name
    await supabaseClient
        .from('users')
        .update({'name': staff.name})
        .eq('id', userUuid);

    // 3. Delete previous records from staff_businesses using staff_id
    await supabaseClient
        .from('staff_businesses')
        .delete()
        .eq('staff_id', userUuid);

    // 4. Insert newly selected businesses
    if (selectedBusinessIds.isNotEmpty) {
      final staffBizInserts = selectedBusinessIds
          .map(
            (bId) => {
              'staff_id': userUuid,
              'business_id': bId,
              'created_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();
      await supabaseClient.from('staff_businesses').insert(staffBizInserts);
    }

    // 5. Delete old permissions
    await supabaseClient
        .from('staff_permissions')
        .delete()
        .eq('user_id', userUuid);

    // 6. Insert permissions again only for selected businesses
    if (selectedBusinessIds.isNotEmpty) {
      final viewTasks =
          staff.customPermissions.contains('view_tasks') ||
          staff.permissions.contains('view_tasks');
      final addTasks =
          staff.customPermissions.contains('add_tasks') ||
          staff.permissions.contains('add_tasks');
      final viewAccounts =
          staff.customPermissions.contains('view_accounts') ||
          staff.permissions.contains('view_accounts');

      final permInserts = selectedBusinessIds
          .map(
            (bId) => {
              'id': const Uuid().v4(),
              'user_id': userUuid,
              'business_id': bId,
              'can_view_tasks': viewTasks,
              'can_add_tasks': addTasks,
              'can_view_accounts': viewAccounts,
            },
          )
          .toList();

      await supabaseClient.from('staff_permissions').insert(permInserts);
    }
  }

  @override
  Future<void> deleteStaff(String userId) async {
    // 1. Resolve user UUID
    final userResponse = await supabaseClient
        .from('users')
        .select('id')
        .eq('userid', userId.trim().toLowerCase())
        .maybeSingle();

    if (userResponse == null) return;

    final String userUuid = userResponse['id'] as String;

    // 2. Delete user only
    await supabaseClient.from('users').delete().eq('id', userUuid);
  }

  @override
  Future<List<StaffBusinessModel>> getStaffBusinesses(String staffId) async {
    final response = await supabaseClient
        .from('staff_businesses')
        .select()
        .eq('staff_id', staffId);

    return (response as List)
        .map((row) => StaffBusinessModel.fromJson(row))
        .toList();
  }
}
