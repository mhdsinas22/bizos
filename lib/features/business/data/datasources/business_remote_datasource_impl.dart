import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/data/datasources/business_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BusinessRemoteDatasourceImpl implements BusinessRemoteDatasource {
  final SupabaseClient supabaseClient;

  BusinessRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<BusinessModel>> getBusinesses(String userStringId) async {
    print("Repository Owner Id: $userStringId");
    // 1. Resolve user profile
    final userResponse = await supabaseClient
        .from('users')
        .select()
        .eq('userid', userStringId.trim().toLowerCase())
        .maybeSingle();

    if (userResponse == null) return [];

    final String userUuid = userResponse['id'] as String;
    final String role = (userResponse['role'] as String).toLowerCase();

    List<Map<String, dynamic>> businessesData = [];

    if (role == 'owner') {
      // Owner fetches all businesses they own
      businessesData = await supabaseClient
          .from('businesses')
          .select()
          .eq('owner_id', userUuid);
    } else {
      // Staff fetches only businesses they are assigned to
      final assignedResponse = await supabaseClient
          .from('staff_businesses')
          .select('business_id')
          .eq('staff_id', userUuid);

      final businessIds = assignedResponse
          .map((row) => row['business_id'] as String)
          .toList();
      if (businessIds.isNotEmpty) {
        businessesData = await supabaseClient
            .from('businesses')
            .select()
            .inFilter('id', businessIds);
      }
    }

    return businessesData.map((row) {
      return BusinessModel(
        id: row['id'] as String,
        name: row['business_name'] as String,
        type: row['business_type'] as String,
        phone: row['phone_number'] as String,
        address: row['address'] as String,
        notes: row['notes'] ?? '',
        ownerId: userStringId, // Return userStringId to keep model consistent
      );
    }).toList();
  }

  @override
  Future<void> createBusiness(BusinessModel business) async {
    // 1. Resolve owner's UUID
    final ownerResponse = await supabaseClient
        .from('users')
        .select('id')
        .eq('userid', business.ownerId.trim().toLowerCase())
        .maybeSingle();

    if (ownerResponse == null) {
      throw Exception('Owner not found in database.');
    }

    final ownerUuid = ownerResponse['id'] as String;

    await supabaseClient.from('businesses').insert({
      'id': business.id,
      'business_name': business.name,
      'business_type': business.type,
      'phone_number': business.phone,
      'address': business.address,
      'notes': business.notes,
      'owner_id': ownerUuid,
    });

    // 2. Automatically grant permissions to all existing staff members belonging to this owner for this business
    final staffList = await supabaseClient
        .from('users')
        .select('id')
        .eq('role', 'Staff')
        .eq('owner_id', ownerUuid);

    if (staffList.isNotEmpty) {
      final permInserts = staffList
          .map(
            (staff) => {
              'id': const Uuid().v4(),
              'user_id': staff['id'],
              'business_id': business.id,
              'can_view_tasks': true,
              'can_add_tasks': true,
              'can_view_accounts': false,
            },
          )
          .toList();

      await supabaseClient.from('staff_permissions').insert(permInserts);
    }
  }

  @override
  Future<void> updateBusiness(BusinessModel business) async {
    await supabaseClient
        .from('businesses')
        .update({
          'business_name': business.name,
          'business_type': business.type,
          'phone_number': business.phone,
          'address': business.address,
          'notes': business.notes,
        })
        .eq('id', business.id);
  }

  @override
  Future<void> deleteBusiness(String id) async {
    // Manual cascade delete for robust DB independence
    await supabaseClient
        .from('staff_permissions')
        .delete()
        .eq('business_id', id);
    await supabaseClient.from('tasks').delete().eq('business_id', id);
    await supabaseClient.from('incomes').delete().eq('business_id', id);
    await supabaseClient.from('expenses').delete().eq('business_id', id);
    await supabaseClient.from('activities').delete().eq('business_id', id);

    // Finally delete the business
    await supabaseClient.from('businesses').delete().eq('id', id);
  }
}
