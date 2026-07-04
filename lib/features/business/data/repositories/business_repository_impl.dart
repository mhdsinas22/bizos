import 'package:bizos/features/business/data/datasources/business_remote_datasource.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDatasource businessRemoteDatasource;
  final DashboardRemoteDatasource dashboardRemoteDatasource;

  BusinessRepositoryImpl({
    required this.businessRemoteDatasource,
    required this.dashboardRemoteDatasource,
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
      await dashboardRemoteDatasource.logActivity(
        businessId: business.id,
        title: "Create Business",
        description: "Business '${business.name}' was created",
        amount: 0.0,
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
      await dashboardRemoteDatasource.logActivity(
        businessId: business.id,
        title: "Update Business",
        description: "Business '${business.name}' was updated",
        amount: 0.0,
      );
    } catch (e) {
      print("Error updating business: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteBusiness(String id) async {
    try {
      await businessRemoteDatasource.deleteBusiness(id);
    } catch (e) {
      print("Error deleting business: $e");
      rethrow;
    }
  }
}
