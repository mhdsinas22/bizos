import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/products_services/data/models/product_service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProductServiceRemoteDatasource {
  Future<List<ProductServiceModel>> getProductsServices(
    String businessId, {
    String? typeFilter,
    String? searchQuery,
    bool activeOnly = false,
  });
  Future<ProductServiceModel> addProductService(ProductServiceModel item);
  Future<ProductServiceModel> updateProductService(ProductServiceModel item);
  Future<void> deleteProductService(String id);
  Future<void> toggleActiveStatus(String id, bool isActive);
}

class ProductServiceRemoteDatasourceImpl implements ProductServiceRemoteDatasource {
  final SupabaseClient supabaseClient;

  ProductServiceRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<ProductServiceModel>> getProductsServices(
    String businessId, {
    String? typeFilter,
    String? searchQuery,
    bool activeOnly = false,
  }) async {
    try {
      if (businessId.trim().isEmpty) return [];

      var query = supabaseClient
          .from('products_services')
          .select()
          .eq('business_id', businessId);

      if (typeFilter != null && typeFilter.trim().isNotEmpty && typeFilter != 'all') {
        query = query.eq('type', typeFilter.trim().toLowerCase());
      }

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = '%${searchQuery.trim().toLowerCase()}%';
        query = query.or('name.ilike.$q,description.ilike.$q');
      }

      final response = await query.order('name', ascending: true);

      return (response as List<dynamic>)
          .map((item) => ProductServiceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch products/services: $e');
    }
  }

  @override
  Future<ProductServiceModel> addProductService(ProductServiceModel item) async {
    try {
      final data = item.toJson();
      final response = await supabaseClient
          .from('products_services')
          .insert(data)
          .select()
          .single();

      return ProductServiceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to add product/service: $e');
    }
  }

  @override
  Future<ProductServiceModel> updateProductService(ProductServiceModel item) async {
    try {
      final data = item.toJson();
      final response = await supabaseClient
          .from('products_services')
          .update(data)
          .eq('id', item.id)
          .select()
          .single();

      return ProductServiceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update product/service: $e');
    }
  }

  @override
  Future<void> deleteProductService(String id) async {
    try {
      await supabaseClient.from('products_services').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete product/service: $e');
    }
  }

  @override
  Future<void> toggleActiveStatus(String id, bool isActive) async {
    try {
      await supabaseClient
          .from('products_services')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to update status: $e');
    }
  }
}
