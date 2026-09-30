import 'package:bizos/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:bizos/features/customers/data/models/customer_model.dart';
import 'package:bizos/features/customers/domain/entities/customer_entity.dart';
import 'package:bizos/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDatasource remoteDatasource;

  CustomerRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<CustomerEntity>> getCustomers(String businessId, {String? searchQuery}) async {
    final models = await remoteDatasource.getCustomers(businessId, searchQuery: searchQuery);
    return List<CustomerEntity>.from(models);
  }

  @override
  Future<CustomerEntity> getCustomerById(String id) {
    return remoteDatasource.getCustomerById(id);
  }

  @override
  Future<CustomerEntity> addCustomer(CustomerEntity customer) {
    final model = CustomerModel.fromEntity(customer);
    return remoteDatasource.addCustomer(model);
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) {
    final model = CustomerModel.fromEntity(customer);
    return remoteDatasource.updateCustomer(model);
  }

  @override
  Future<void> deleteCustomer(String id) {
    return remoteDatasource.deleteCustomer(id);
  }

  @override
  Future<Map<String, dynamic>> getCustomerFinancialSummary(String customerId) {
    return remoteDatasource.getCustomerFinancialSummary(customerId);
  }
}
