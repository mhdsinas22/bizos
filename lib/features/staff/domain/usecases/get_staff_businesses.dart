import 'package:bizos/features/staff/data/models/staff_business_model.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';

class GetStaffBusinesses {
  final StaffRepository repository;

  GetStaffBusinesses(this.repository);

  Future<List<StaffBusinessModel>> call(String staffId) async {
    return await repository.getStaffBusinesses(staffId);
  }
}
