import 'package:bizos/features/auth/data/models/user_model.dart';

abstract class StaffEvent {}

class FetchStaffEvent extends StaffEvent {
  final String ownerId;
  FetchStaffEvent(this.ownerId);
}

class CreateStaffEvent extends StaffEvent {
  final UserModel staff;
  final String ownerId;
  final List<String> selectedBusinessIds;
  CreateStaffEvent(this.staff, this.ownerId, this.selectedBusinessIds);
}

class UpdateStaffEvent extends StaffEvent {
  final UserModel staff;
  final String ownerId;
  UpdateStaffEvent(this.staff, this.ownerId);
}

class DeleteStaffEvent extends StaffEvent {
  final String userId;
  final String ownerId;
  DeleteStaffEvent(this.userId, this.ownerId);
}
