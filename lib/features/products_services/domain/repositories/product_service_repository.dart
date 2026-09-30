import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';

abstract class ProductServiceRepository {
  Future<List<ProductServiceEntity>> getProductsServices(
    String businessId, {
    String? typeFilter,
    String? searchQuery,
    bool activeOnly = false,
  });
  Future<ProductServiceEntity> addProductService(ProductServiceEntity item);
  Future<ProductServiceEntity> updateProductService(ProductServiceEntity item);
  Future<void> deleteProductService(String id);
  Future<void> toggleActiveStatus(String id, bool isActive);
}
