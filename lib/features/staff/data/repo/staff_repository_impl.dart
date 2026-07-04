import 'package:bizos/features/staff/data/datasource/staff_remote_datasource.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDatasource staffRemoteDatasource;
  final DashboardRemoteDatasource  dashboardRemoteDatasource;

  StaffRepositoryImpl({
    required this.staffRemoteDatasource,
    required this.dashboardRemoteDatasource,
  });

  @override
  Future<List<UserModel>> getStaffList(String ownerId) async {
    try {
      print("staff reposr owenid:-${ownerId}");
      return await staffRemoteDatasource.getStaffList(ownerId);
    } catch (e) {
      print("Error fetching staff List: $e");
      rethrow;
    }
  }

  @override
  Future<void> createStaff(
    UserModel staff,
    String ownerId,
    List<String> selectedBusinessIds,
  ) async {
    try {
      await staffRemoteDatasource.createStaff(
        staff,
        ownerId,
        selectedBusinessIds,
      );
      // Automatically log activity
      await dashboardRemoteDatasource.logActivity(
        businessId: null,
        title: "Create Staff",
        description: "Staff member '${staff.name}' was registered",
        amount: 0.0,
      );
    } catch (e) {
      print("Error creating staff: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateStaff(UserModel staff) async {
    try {
      await staffRemoteDatasource.updateStaff(staff);
    } catch (e) {
      print("Error updating staff: $e"); 
      rethrow;
    }
  }

  @override
  Future<void> deleteStaff(String userId) async {
    try {
      await staffRemoteDatasource.deleteStaff(userId);
    } catch (e) {
      print("Error deleting staff: $e");
      rethrow;
    }
  }
}
