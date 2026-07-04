import 'package:bizos/features/business/data/models/business_model.dart';

abstract class BusinessEvent {}

class FetchBusinessesEvent extends BusinessEvent {
  final String ownerId;
  FetchBusinessesEvent(this.ownerId);
}

class CreateBusinessEvent extends BusinessEvent {
  final BusinessModel business;
  CreateBusinessEvent(this.business);
}

class UpdateBusinessEvent extends BusinessEvent {
  final BusinessModel business;
  UpdateBusinessEvent(this.business);
}

class DeleteBusinessEvent extends BusinessEvent {
  final String id;
  final String ownerId;
  DeleteBusinessEvent(this.id, this.ownerId);
}
