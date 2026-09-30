import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/customers/data/models/customer_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CustomerRemoteDatasource {
  Future<List<CustomerModel>> getCustomers(String businessId, {String? searchQuery});
  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> addCustomer(CustomerModel customer);
  Future<CustomerModel> updateCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<Map<String, dynamic>> getCustomerFinancialSummary(String customerId);
}

class CustomerRemoteDatasourceImpl implements CustomerRemoteDatasource {
  final SupabaseClient supabaseClient;

  CustomerRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<CustomerModel>> getCustomers(String businessId, {String? searchQuery}) async {
    try {
      if (businessId.trim().isEmpty) return [];

      var query = supabaseClient
          .from('customers')
          .select()
          .eq('business_id', businessId);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = '%${searchQuery.trim().toLowerCase()}%';
        query = query.or('name.ilike.$q,phone.ilike.$q,email.ilike.$q');
      }

      final response = await query.order('name', ascending: true);

      return (response as List<dynamic>)
          .map((item) => CustomerModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch customers: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await supabaseClient
          .from('customers')
          .select()
          .eq('id', id)
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch customer details: $e');
    }
  }

  @override
  Future<CustomerModel> addCustomer(CustomerModel customer) async {
    try {
      final data = customer.toJson();
      final response = await supabaseClient
          .from('customers')
          .insert(data)
          .select()
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to add customer: $e');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    try {
      final data = customer.toJson();
      final response = await supabaseClient
          .from('customers')
          .update(data)
          .eq('id', customer.id)
          .select()
          .single();

      return CustomerModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update customer: $e');
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await supabaseClient.from('customers').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete customer: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerFinancialSummary(String customerId) async {
    try {
      final response = await supabaseClient
          .from('invoices')
          .select('grand_total, paid_amount, balance_amount, status')
          .eq('customer_id', customerId);

      double totalInvoiced = 0.0;
      double totalPaid = 0.0;
      double totalOutstanding = 0.0;

      for (final row in response as List<dynamic>) {
        final status = (row['status'] as String? ?? '').toLowerCase();
        if (status == 'cancelled') continue;

        totalInvoiced += (row['grand_total'] as num?)?.toDouble() ?? 0.0;
        totalPaid += (row['paid_amount'] as num?)?.toDouble() ?? 0.0;
        totalOutstanding += (row['balance_amount'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'totalInvoiced': totalInvoiced,
        'totalPaid': totalPaid,
        'totalOutstanding': totalOutstanding,
        'invoiceCount': (response as List).length,
      };
    } catch (e) {
      return {
        'totalInvoiced': 0.0,
        'totalPaid': 0.0,
        'totalOutstanding': 0.0,
        'invoiceCount': 0,
      };
    }
  }
}
