import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/products_services/domain/entities/product_service_entity.dart';
import 'package:bizos/features/products_services/domain/repositories/product_service_repository.dart';

// EVENTS
abstract class ProductServiceEvent extends Equatable {
  const ProductServiceEvent();
  @override
  List<Object?> get props => [];
}

class FetchProductsServicesEvent extends ProductServiceEvent {
  final String businessId;
  final String? typeFilter;
  final String? searchQuery;
  final bool activeOnly;

  const FetchProductsServicesEvent({
    required this.businessId,
    this.typeFilter = 'all',
    this.searchQuery,
    this.activeOnly = false,
  });

  @override
  List<Object?> get props => [businessId, typeFilter, searchQuery, activeOnly];
}

class AddProductServiceEvent extends ProductServiceEvent {
  final ProductServiceEntity item;

  const AddProductServiceEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class UpdateProductServiceEvent extends ProductServiceEvent {
  final ProductServiceEntity item;

  const UpdateProductServiceEvent(this.item);

  @override
  List<Object?> get props => [item];
}

class DeleteProductServiceEvent extends ProductServiceEvent {
  final String itemId;
  final String businessId;

  const DeleteProductServiceEvent({required this.itemId, required this.businessId});

  @override
  List<Object?> get props => [itemId, businessId];
}

class ToggleProductServiceActiveEvent extends ProductServiceEvent {
  final String itemId;
  final bool isActive;
  final String businessId;

  const ToggleProductServiceActiveEvent({
    required this.itemId,
    required this.isActive,
    required this.businessId,
  });

  @override
  List<Object?> get props => [itemId, isActive, businessId];
}

// STATES
abstract class ProductServiceState extends Equatable {
  const ProductServiceState();
  @override
  List<Object?> get props => [];
}

class ProductServiceInitial extends ProductServiceState {}

class ProductServiceLoading extends ProductServiceState {}

class ProductServiceLoaded extends ProductServiceState {
  final List<ProductServiceEntity> items;
  final String typeFilter;
  final String? searchQuery;

  const ProductServiceLoaded({
    required this.items,
    this.typeFilter = 'all',
    this.searchQuery,
  });

  @override
  List<Object?> get props => [items, typeFilter, searchQuery];
}

class ProductServiceActionSuccess extends ProductServiceState {
  final String message;
  const ProductServiceActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ProductServiceError extends ProductServiceState {
  final String message;

  const ProductServiceError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class ProductServiceBloc extends Bloc<ProductServiceEvent, ProductServiceState> {
  final ProductServiceRepository repository;

  ProductServiceBloc({required this.repository}) : super(ProductServiceInitial()) {
    on<FetchProductsServicesEvent>(_onFetch);
    on<AddProductServiceEvent>(_onAdd);
    on<UpdateProductServiceEvent>(_onUpdate);
    on<DeleteProductServiceEvent>(_onDelete);
    on<ToggleProductServiceActiveEvent>(_onToggleActive);
  }

  Future<void> _onFetch(
    FetchProductsServicesEvent event,
    Emitter<ProductServiceState> emit,
  ) async {
    emit(ProductServiceLoading());
    try {
      final items = await repository.getProductsServices(
        event.businessId,
        typeFilter: event.typeFilter,
        searchQuery: event.searchQuery,
        activeOnly: event.activeOnly,
      );
      emit(ProductServiceLoaded(
        items: items,
        typeFilter: event.typeFilter ?? 'all',
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(ProductServiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAdd(
    AddProductServiceEvent event,
    Emitter<ProductServiceState> emit,
  ) async {
    emit(ProductServiceLoading());
    try {
      await repository.addProductService(event.item);
      emit(const ProductServiceActionSuccess('Item added successfully'));
      add(FetchProductsServicesEvent(businessId: event.item.businessId));
    } catch (e) {
      emit(ProductServiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdate(
    UpdateProductServiceEvent event,
    Emitter<ProductServiceState> emit,
  ) async {
    emit(ProductServiceLoading());
    try {
      await repository.updateProductService(event.item);
      emit(const ProductServiceActionSuccess('Item updated successfully'));
      add(FetchProductsServicesEvent(businessId: event.item.businessId));
    } catch (e) {
      emit(ProductServiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDelete(
    DeleteProductServiceEvent event,
    Emitter<ProductServiceState> emit,
  ) async {
    emit(ProductServiceLoading());
    try {
      await repository.deleteProductService(event.itemId);
      emit(const ProductServiceActionSuccess('Item deleted successfully'));
      add(FetchProductsServicesEvent(businessId: event.businessId));
    } catch (e) {
      emit(ProductServiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onToggleActive(
    ToggleProductServiceActiveEvent event,
    Emitter<ProductServiceState> emit,
  ) async {
    try {
      await repository.toggleActiveStatus(event.itemId, event.isActive);
      add(FetchProductsServicesEvent(businessId: event.businessId));
    } catch (e) {
      emit(ProductServiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
