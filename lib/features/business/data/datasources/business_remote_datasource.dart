import 'package:bizos/features/business/data/models/business_model.dart';

abstract class BusinessRemoteDatasource {
  Future<List<BusinessModel>> getBusinesses(String userStringId);
  Future<void> createBusiness(BusinessModel business);
  Future<void> updateBusiness(BusinessModel business);
  Future<void> deleteBusiness(String id);
}
