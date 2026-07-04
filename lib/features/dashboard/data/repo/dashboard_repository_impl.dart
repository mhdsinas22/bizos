import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource dashboardRemoteDatasource;

  DashboardRepositoryImpl({required this.dashboardRemoteDatasource});

  @override
  Future<DashboardData> getDashboardData(
    String? businessId,
    String currentuserid,
  ) async {
    try {
      return await dashboardRemoteDatasource.getDashboardData(
        businessId,
        currentuserid,
      );
    } catch (e) {
      print("Error fetching dashboard data: $e");
      rethrow;
    }
  }

  @override
  Future<void> logActivity({
    String? businessId,
    required String title,
    required String description,
    required double amount,
  }) async {
    try {
      await dashboardRemoteDatasource.logActivity(
        businessId: businessId,
        title: title,
        description: description,
        amount: amount,
      );
    } catch (e) {
      print("Error logging activity: $e");
    }
  }

  @override
  Future<DashboardData> getSpecificBusinessData(String businessId) async {
    try {
      return await dashboardRemoteDatasource.getSpecificBusinessData(
        businessId,
      );
    } catch (e) {
      print("Error fetching specific business data: $e");
      rethrow;
    }
  }
}
