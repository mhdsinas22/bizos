import 'package:bizos/features/staff/data/datasource/staff_remote_datasource.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/data/models/staff_business_model.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDatasource staffRemoteDatasource;
  final ActivityRepository activityRepository;

  StaffRepositoryImpl({
    required this.staffRemoteDatasource,
    required this.activityRepository,
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
      await activityRepository.logActivity(
        businessId: null,
        title: "Staff Added",
        description: "Staff member '${staff.name}' was registered",
        module: "Staff",
        action: "Add",
        referenceId: staff.id,
      );
    } catch (e) {
      print("Error creating staff: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateStaff(
    UserModel staff,
    List<String> selectedBusinessIds,
  ) async {
    try {
      await staffRemoteDatasource.updateStaff(staff, selectedBusinessIds);
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: null,
        title: "Staff Updated",
        description: "Staff member '${staff.name}' details were updated",
        module: "Staff",
        action: "Update",
        referenceId: staff.id,
      );
    } catch (e) {
      print("Error updating staff: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteStaff(String userId) async {
    try {
      final name = await staffRemoteDatasource.deleteStaff(userId);
      if (name != null) {
        // Automatically log activity
        await activityRepository.logActivity(
          businessId: null,
          title: "Staff Deleted",
          description: "Staff member '$name' was deleted",
          module: "Staff",
          action: "Delete",
        );
      }
    } catch (e) {
      print("Error deleting staff: $e");
      rethrow;
    }
  }

  @override
  Future<List<StaffBusinessModel>> getStaffBusinesses(String staffId) async {
    try {
      print('staff repository getStaffBusinesses id:-$staffId');
      return await staffRemoteDatasource.getStaffBusinesses(staffId);
    } catch (e) {
      print('staff repository getStaffBusinesses error:-$e');
      rethrow;
    }
  }
}
