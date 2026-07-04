import 'package:bizos/features/business/data/models/business_model.dart';

abstract class BusinessRepository {
  Future<List<BusinessModel>> getBusinesses(String ownerId);
  Future<void> createBusiness(BusinessModel business);
  Future<void> updateBusiness(BusinessModel business);
  Future<void> deleteBusiness(String id);
}
