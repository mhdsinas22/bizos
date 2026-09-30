import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/customers/domain/entities/customer_entity.dart';
import 'package:bizos/features/customers/domain/repositories/customer_repository.dart';

// EVENTS
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class FetchCustomersEvent extends CustomerEvent {
  final String businessId;
  final String? searchQuery;

  const FetchCustomersEvent({required this.businessId, this.searchQuery});

  @override
  List<Object?> get props => [businessId, searchQuery];
}

class AddCustomerEvent extends CustomerEvent {
  final CustomerEntity customer;

  const AddCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class UpdateCustomerEvent extends CustomerEvent {
  final CustomerEntity customer;

  const UpdateCustomerEvent(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String customerId;
  final String businessId;

  const DeleteCustomerEvent({required this.customerId, required this.businessId});

  @override
  List<Object?> get props => [customerId, businessId];
}

class FetchCustomerSummaryEvent extends CustomerEvent {
  final String customerId;

  const FetchCustomerSummaryEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

// STATES
abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerEntity> customers;
  final String? searchQuery;

  const CustomerLoaded({required this.customers, this.searchQuery});

  @override
  List<Object?> get props => [customers, searchQuery];
}

class CustomerSummaryLoaded extends CustomerState {
  final CustomerEntity customer;
  final Map<String, dynamic> summary;

  const CustomerSummaryLoaded({required this.customer, required this.summary});

  @override
  List<Object?> get props => [customer, summary];
}

class CustomerActionSuccess extends CustomerState {
  final String message;
  const CustomerActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository repository;

  CustomerBloc({required this.repository}) : super(CustomerInitial()) {
    on<FetchCustomersEvent>(_onFetchCustomers);
    on<AddCustomerEvent>(_onAddCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<FetchCustomerSummaryEvent>(_onFetchCustomerSummary);
  }

  Future<void> _onFetchCustomers(
    FetchCustomersEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customers = await repository.getCustomers(
        event.businessId,
        searchQuery: event.searchQuery,
      );
      emit(CustomerLoaded(customers: customers, searchQuery: event.searchQuery));
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      await repository.addCustomer(event.customer);
      emit(const CustomerActionSuccess('Customer added successfully'));
      add(FetchCustomersEvent(businessId: event.customer.businessId));
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      await repository.updateCustomer(event.customer);
      emit(const CustomerActionSuccess('Customer updated successfully'));
      add(FetchCustomersEvent(businessId: event.customer.businessId));
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      await repository.deleteCustomer(event.customerId);
      emit(const CustomerActionSuccess('Customer deleted successfully'));
      add(FetchCustomersEvent(businessId: event.businessId));
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchCustomerSummary(
    FetchCustomerSummaryEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      final customer = await repository.getCustomerById(event.customerId);
      final summary = await repository.getCustomerFinancialSummary(event.customerId);
      emit(CustomerSummaryLoaded(customer: customer, summary: summary));
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
