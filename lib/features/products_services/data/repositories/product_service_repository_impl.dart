import 'package:bizos/features/products_services/data/datasources/product_service_remote_datasource.dart';
import 'package:bizos/features/products_services/data/models/product_service_model.dart';
import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';
import 'package:bizos/features/products_services/domain/repositories/product_service_repository.dart';

class ProductServiceRepositoryImpl implements ProductServiceRepository {
  final ProductServiceRemoteDatasource remoteDatasource;

  ProductServiceRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<ProductServiceEntity>> getProductsServices(
    String businessId, {
    String? typeFilter,
    String? searchQuery,
    bool activeOnly = false,
  }) async {
    final models = await remoteDatasource.getProductsServices(
      businessId,
      typeFilter: typeFilter,
      searchQuery: searchQuery,
      activeOnly: activeOnly,
    );
    return List<ProductServiceEntity>.from(models);
  }

  @override
  Future<ProductServiceEntity> addProductService(ProductServiceEntity item) {
    final model = ProductServiceModel.fromEntity(item);
    return remoteDatasource.addProductService(model);
  }

  @override
  Future<ProductServiceEntity> updateProductService(ProductServiceEntity item) {
    final model = ProductServiceModel.fromEntity(item);
    return remoteDatasource.updateProductService(model);
  }

  @override
  Future<void> deleteProductService(String id) {
    return remoteDatasource.deleteProductService(id);
  }

  @override
  Future<void> toggleActiveStatus(String id, bool isActive) {
    return remoteDatasource.toggleActiveStatus(id, isActive);
  }
}
