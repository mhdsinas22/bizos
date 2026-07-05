import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/staff/data/models/staff_business_model.dart';

abstract class StaffState {}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<UserModel> staffList;
  final List<StaffBusinessModel> assignedBusinesses;
  StaffLoaded(this.staffList, [this.assignedBusinesses = const []]);
}

class StaffError extends StaffState {
  final String message;
  StaffError(this.message);
}
