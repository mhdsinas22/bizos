import 'package:bizos/core/utils/app_logger.dart';
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
    AppLogger.info("ownerId:-$ownerId");
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
    final cleanEmail = staff.email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('A valid staff email address is required.');
    }
    if (staff.password.isEmpty || staff.password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    // 1. Invoke Supabase Edge Function to provision staff account securely
    try {
      final response = await supabaseClient.functions.invoke(
        'create-staff-account',
        body: {
          'name': staff.name.trim(),
          'email': cleanEmail,
          'password': staff.password,
          'phone': staff.phone.trim(),
          'userId': staff.userId.isNotEmpty
              ? staff.userId.trim()
              : cleanEmail.split('@')[0],
          'selectedBusinessIds': selectedBusinessIds,
          'permissions': staff.permissions,
        },
      );

      if (response.status == 200 || response.status == 201) {
        final dynamic data = response.data;
        if (data is Map && data['error'] != null) {
          throw Exception(data['error'].toString());
        }
        return;
      } else {
        final dynamic data = response.data;
        final errorMsg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Staff account creation failed (Status: ${response.status})';
        throw Exception(errorMsg);
      }
    } on FunctionException catch (e) {
      AppLogger.error('Edge function error creating staff: ${e.details}');
      final dynamic details = e.details;
      if (details is Map && details['error'] != null) {
        throw Exception(details['error'].toString());
      }
      if (details != null && details.toString().isNotEmpty) {
        throw Exception(details.toString());
      }
      throw Exception('Staff account provisioning failed (status: ${e.status}).');
    } catch (e) {
      AppLogger.error('Error in createStaff: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStaff(
    UserModel staff,
    List<String> selectedBusinessIds,
  ) async {
    // 1. Resolve user UUID by staff.id or email/userid
    String? userUuid;
    if (staff.id.isNotEmpty) {
      userUuid = staff.id;
    } else {
      final userResponse = await supabaseClient
          .from('users')
          .select('id')
          .or(
            'email.eq.${staff.email.trim().toLowerCase()},userid.eq.${staff.userId.trim().toLowerCase()}',
          )
          .maybeSingle();
      userUuid = userResponse?['id'] as String?;
    }

    if (userUuid == null) {
      throw Exception('Staff member not found.');
    }

    // 2. Update user name and phone
    await supabaseClient
        .from('users')
        .update({'name': staff.name, 'phone': staff.phone})
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
  Future<String?> deleteStaff(String identifier) async {
    final clean = identifier.trim().toLowerCase();
    Map<String, dynamic>? userResponse;

    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(clean);

    if (isUuid) {
      userResponse = await supabaseClient
          .from('users')
          .select('id, name')
          .eq('id', clean)
          .maybeSingle();
    }

    userResponse ??= await supabaseClient
        .from('users')
        .select('id, name')
        .or('email.eq.$clean,userid.eq.$clean')
        .maybeSingle();

    if (userResponse == null) return null;

    final String userUuid = userResponse['id'] as String;
    final String name = userResponse['name'] as String;

    // Delete user record from database
    await supabaseClient.from('users').delete().eq('id', userUuid);
    return name;
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

  @override
  Future<List<UserModel>> getStaffByBusiness(String businessId) async {
    final response = await supabaseClient
        .from('staff_businesses')
        .select('staff_id')
        .eq('business_id', businessId);

    final staffIds = (response as List)
        .map((row) => row['staff_id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();

    if (staffIds.isEmpty) return [];

    final usersResponse = await supabaseClient
        .from('users')
        .select()
        .inFilter('id', staffIds);

    final staffList = <UserModel>[];

    for (var row in (usersResponse as List)) {
      final userMap = Map<String, dynamic>.from(row);
      staffList.add(UserModel.fromJson(userMap));
    }

    return staffList;
  }
}
