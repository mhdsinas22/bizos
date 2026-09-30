import 'dart:convert';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/core/utils/app_logger.dart';
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
      // 1. Resolve allowed business IDs if business mode
      List<String> allowedBusinessIds = [];
      if (!isPersonal) {
        if (isOwner) {
          final ownedResp = await supabaseClient
              .from('businesses')
              .select('id')
              .eq('owner_id', userId);

          allowedBusinessIds = (ownedResp as List)
              .map((row) => row['id'] as String)
              .toList();
        } else {
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
      }

      // Helper function to build filter conditions on postgrest query
      PostgrestFilterBuilder<T> applyFilters<T>(
        PostgrestFilterBuilder<T> queryBuilder,
      ) {
        var query = queryBuilder;
        if (isPersonal) {
          query = query.isFilter('business_id', null).eq('created_by', userId);
        } else {
          if (businessId != null &&
              businessId.isNotEmpty &&
              businessId != 'all') {
            if (!allowedBusinessIds.contains(businessId)) {
              return query.eq('business_id', 'invalid_id_not_found');
            }
            query = query.eq('business_id', businessId);
          } else {
            query = query.inFilter('business_id', allowedBusinessIds);
          }
        }

        if (startDate != null) {
          query = query.gte('created_at', startDate.toIso8601String());
        }
        if (endDate != null) {
          query = query.lte('created_at', endDate.toIso8601String());
        }

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final escaped = '%${searchQuery.trim()}%';
          query = query.or('title.ilike.$escaped,description.ilike.$escaped');
        }

        return query;
      }

      final from = (page - 1) * limit;
      final to = from + limit - 1;

      List<dynamic> response;
      try {
        var query = supabaseClient
            .from('activities')
            .select('*, users:created_by(name)');
        query = applyFilters(query);
        response = await query
            .order('created_at', ascending: false)
            .range(from, to);
      } catch (e) {
        AppLogger.error(
          'Warning: FK join failed or missing, using fallback query: $e',
        );
        var query = supabaseClient.from('activities').select();
        query = applyFilters(query);
        response = await query
            .order('created_at', ascending: false)
            .range(from, to);
      }

      // Collect any missing created_by user names for rows where users join was null/empty
      final missingUserIds = (response)
          .map((row) => (row as Map)['created_by'] as String?)
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      Map<String, String> userNamesMap = {};
      if (missingUserIds.isNotEmpty) {
        try {
          final usersResp = await supabaseClient
              .from('users')
              .select('id, name')
              .inFilter('id', missingUserIds);
          for (var u in (usersResp as List)) {
            final uid = u['id'] as String;
            final uname = (u['name'] as String?)?.trim() ?? 'Unknown User';
            userNamesMap[uid] = uname.isNotEmpty ? uname : 'Unknown User';
          }
        } catch (e) {
          AppLogger.error('Warning: failed to fetch user names batch: $e');
        }
      }

      return response.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        if (map['users'] == null && map['created_by'] != null) {
          final uName = userNamesMap[map['created_by']];
          if (uName != null) {
            map['created_by_name'] = uName;
          }
        }
        return ActivityModel.fromJson(map);
      }).toList();
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
      if (resolvedCreatedBy == null || resolvedCreatedBy.trim().isEmpty) {
        resolvedCreatedBy = supabaseClient.auth.currentUser?.id;
      }
      if (resolvedCreatedBy == null || resolvedCreatedBy.trim().isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('logged_in_user');
        if (userJson != null) {
          final userMap = jsonDecode(userJson);
          resolvedCreatedBy = userMap['id']?.toString();
        }
      }

      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (resolvedCreatedBy != null && !uuidRegex.hasMatch(resolvedCreatedBy)) {
        resolvedCreatedBy = null;
      }

      final uuid = const Uuid().v4();

      await supabaseClient.from('activities').insert({
        'id': uuid,
        'business_id': (businessId != null && businessId.trim().isNotEmpty)
            ? businessId
            : null,
        'title': title,
        'description': description,
        'created_by':
            (resolvedCreatedBy != null && resolvedCreatedBy.trim().isNotEmpty)
            ? resolvedCreatedBy
            : null,
        'module': module,
        'action': action,
        'reference_id': (referenceId != null && referenceId.trim().isNotEmpty)
            ? referenceId
            : null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('Warning: failed to log activity: $e');
    }
  }
}
