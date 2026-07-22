import 'package:bizos/features/business/data/datasources/business_remote_datasource.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDatasource businessRemoteDatasource;
  final ActivityRepository activityRepository;

  BusinessRepositoryImpl({
    required this.businessRemoteDatasource,
    required this.activityRepository,
  });

  @override
  Future<List<BusinessModel>> getBusinesses(String ownerId) async {
    try {
      return await businessRemoteDatasource.getBusinesses(ownerId);
    } catch (e) {
      print("Error fetching businesses: $e");
      rethrow;
    }
  }

  @override
  Future<void> createBusiness(BusinessModel business) async {
    try {
      await businessRemoteDatasource.createBusiness(business);
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: business.id,
        title: "Business Created",
        description: "Business '${business.name}' was created",
        module: "Business",
        action: "Create",
        referenceId: business.id,
      );
    } catch (e) {
      print("Error creating business: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateBusiness(BusinessModel business) async {
    try {
      await businessRemoteDatasource.updateBusiness(business);
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: business.id,
        title: "Business Updated",
        description: "Business '${business.name}' was updated",
        module: "Business",
        action: "Update",
        referenceId: business.id,
      );
    } catch (e) {
      print("Error updating business: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteBusiness(String id) async {
    try {
      final deleted = await businessRemoteDatasource.deleteBusiness(id);
      if (deleted != null) {
        // Automatically log activity
        await activityRepository.logActivity(
          businessId: deleted.id,
          title: "Business Deleted",
          description: "Business '${deleted.name}' was deleted",
          module: "Business",
          action: "Delete",
          referenceId: deleted.id,
        );
      }
    } catch (e) {
      print("Error deleting business: $e");
      rethrow;
    }
  }
}
