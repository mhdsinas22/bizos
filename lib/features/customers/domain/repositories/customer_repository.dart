import 'package:bizos/features/customers/domain/entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getCustomers(String businessId, {String? searchQuery});
  Future<CustomerEntity> getCustomerById(String id);
  Future<CustomerEntity> addCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
  Future<Map<String, dynamic>> getCustomerFinancialSummary(String customerId);
}
