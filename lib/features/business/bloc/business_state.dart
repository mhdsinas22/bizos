import 'package:bizos/features/business/data/models/business_model.dart';

abstract class BusinessState {}

class BusinessInitial extends BusinessState {}

class BusinessLoading extends BusinessState {}

class BusinessLoaded extends BusinessState {
  final List<BusinessModel> businesses;
  BusinessLoaded(this.businesses);
}

class BusinessError extends BusinessState {
  final String message;
  BusinessError(this.message);
}
