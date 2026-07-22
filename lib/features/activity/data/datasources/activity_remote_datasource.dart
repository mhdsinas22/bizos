import 'dart:convert';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/activity/data/models/activity_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class ActivityRemoteDatasource {
  Future<List<ActivityModel>> getActivities({
    required String userId,
    required bool isOwner,
    required bool isPersonal,
    String? businessId,
    List<String>? assignedBusinessIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    required int page,
    required int limit,
  });

  Future<void> logActivity({
    String? businessId,
    required String title,
    required String description,
    required String module,
    required String action,
    String? referenceId,
    String? createdBy,
  });
}

class ActivityRemoteDatasourceImpl implements ActivityRemoteDatasource {
  final SupabaseClient supabaseClient;

  ActivityRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<ActivityModel>> getActivities({
    required String userId,
    required bool isOwner,
    required bool isPersonal,
    String? businessId,
    List<String>? assignedBusinessIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    required int page,
    required int limit,
  }) async {
    try {
      var query = supabaseClient.from('activities').select();

      // 1. Filter by Personal vs Business
      if (isPersonal) {
        // Personal activities belong strictly to the logged-in user
        query = query.isFilter('business_id', null).eq('created_by', userId);
      } else {
        // Business Activities: Must be restricted to businesses owned by or assigned to this user
        List<String> allowedBusinessIds = [];

        if (isOwner) {
          // Fetch all business IDs owned by this owner user
          final ownedResp = await supabaseClient
              .from('businesses')
              .select('id')
              .eq('owner_id', userId);

          allowedBusinessIds = (ownedResp as List)
              .map((row) => row['id'] as String)
              .toList();
        } else {
          // Staff user
          if (assignedBusinessIds != null && assignedBusinessIds.isNotEmpty) {
            allowedBusinessIds = List<String>.from(assignedBusinessIds);
          } else {
            final staffResp = await supabaseClient
                .from('staff_businesses')
                .select('business_id')
                .eq('staff_id', userId);

            allowedBusinessIds = (staffResp as List)
                .map((row) => row['business_id'] as String)
                .toList();
          }
        }

        if (allowedBusinessIds.isEmpty) {
          return [];
        }

        if (businessId != null &&
            businessId.isNotEmpty &&
            businessId != 'all') {
          // Verify that the requested businessId is within user's allowed businesses
          if (!allowedBusinessIds.contains(businessId)) {
            return [];
          }
          query = query.eq('business_id', businessId);
        } else {
          // "All Businesses" option: filter by ALL businesses owned/assigned to this user
          query = query.inFilter('business_id', allowedBusinessIds);
        }
      }

      // 2. Filter by date range
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // 3. Search query
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final escaped = '%${searchQuery.trim()}%';
        query = query.or('title.ilike.$escaped,description.ilike.$escaped');
      }

      // 4. Order and Pagination
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List)
          .map((row) => ActivityModel.fromJson(row))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get activities: $e');
    }
  }

  @override
  Future<void> logActivity({
    String? businessId,
    required String title,
    required String description,
    required String module,
    required String action,
    String? referenceId,
    String? createdBy,
  }) async {
    try {
      String? resolvedCreatedBy = createdBy;
      if (resolvedCreatedBy == null || resolvedCreatedBy.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('logged_in_user');
        if (userJson != null) {
          final userMap = jsonDecode(userJson);
          resolvedCreatedBy = userMap['id']?.toString();
        }
      }

      // Since created_by is a UUID column in the DB, verify it's a valid UUID to avoid PostgreSQL insertion crash
      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (resolvedCreatedBy != null && !uuidRegex.hasMatch(resolvedCreatedBy)) {
        resolvedCreatedBy = null;
      }

      final uuid = const Uuid().v4();

      await supabaseClient.from('activities').insert({
        'id': uuid,
        'business_id': businessId,
        'title': title,
        'description': description,
        'created_by': resolvedCreatedBy,
        'module': module,
        'action': action,
        'reference_id': referenceId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Warning: failed to log activity: $e');
    }
  }
}
