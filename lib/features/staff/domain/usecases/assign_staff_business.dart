import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';

class AssignStaffBusiness {
  final StaffRepository repository;

  AssignStaffBusiness(this.repository);

  Future<void> call(UserModel staff, List<String> businessIds) async {
    await repository.updateStaff(staff, businessIds);
  }
}
