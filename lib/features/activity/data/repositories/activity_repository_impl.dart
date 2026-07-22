import 'package:bizos/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:bizos/features/activity/domain/entities/activity_entity.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDatasource activityRemoteDatasource;

  ActivityRepositoryImpl({required this.activityRemoteDatasource});

  @override
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
  }) async {
    return await activityRemoteDatasource.getActivities(
      userId: userId,
      isOwner: isOwner,
      isPersonal: isPersonal,
      businessId: businessId,
      assignedBusinessIds: assignedBusinessIds,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery,
      page: page,
      limit: limit,
    );
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
    await activityRemoteDatasource.logActivity(
      businessId: businessId,
      title: title,
      description: description,
      module: module,
      action: action,
      referenceId: referenceId,
      createdBy: createdBy,
    );
  }
}
