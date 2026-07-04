import 'package:bizos/features/auth/data/models/user_model.dart';

abstract class StaffRepository {
  Future<List<UserModel>> getStaffList(String ownerId);
  Future<void> createStaff(
    UserModel staff,
    String ownerId,
    List<String> selectedBusinessIds,
  );
  Future<void> updateStaff(UserModel staff);
  Future<void> deleteStaff(String userId);
}
