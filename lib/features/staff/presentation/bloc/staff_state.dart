import 'package:bizos/features/auth/data/models/user_model.dart';

abstract class StaffState {}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<UserModel> staffList;
  StaffLoaded(this.staffList);
}

class StaffError extends StaffState {
  final String message;
  StaffError(this.message);
}
