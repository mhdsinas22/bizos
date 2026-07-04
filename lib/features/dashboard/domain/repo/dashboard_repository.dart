import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData(
    String? businessId,
    String currentuserid,
  );
  Future<void> logActivity({
    String? businessId,
    required String title,
    required String description,
    required double amount,
  });
  Future<DashboardData> getSpecificBusinessData(String businessId);
}
