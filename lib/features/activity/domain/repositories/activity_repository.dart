import 'package:bizos/features/activity/domain/entities/activity_entity.dart';

abstract class ActivityRepository {
  Future<List<ActivityEntity>> getActivities({
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
