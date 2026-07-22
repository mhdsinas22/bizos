import 'package:bizos/features/activity/domain/entities/activity_entity.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';

class GetActivities {
  final ActivityRepository repository;

  GetActivities(this.repository);

  Future<List<ActivityEntity>> call({
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
  }) {
    return repository.getActivities(
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
}
