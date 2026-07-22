import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/data/models/staff_business_model.dart';

abstract class StaffRemoteDatasource {
  Future<List<UserModel>> getStaffList(String ownerId);
  Future<void> createStaff(
    UserModel staff,
    String ownerId,
    List<String> selectedBusinessIds,
  );
  Future<void> updateStaff(UserModel staff, List<String> selectedBusinessIds);
  Future<String?> deleteStaff(String userId);
  Future<List<StaffBusinessModel>> getStaffBusinesses(String staffId);
}
