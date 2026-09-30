import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';
import 'package:bizos/features/invoices/domain/repositories/invoice_repository.dart';

// EVENTS
abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class FetchInvoicesEvent extends InvoiceEvent {
  final String businessId;
  final String? statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;
  final String? searchQuery;

  const FetchInvoicesEvent({
    required this.businessId,
    this.statusFilter = 'all',
    this.startDate,
    this.endDate,
    this.customerId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        businessId,
        statusFilter,
        startDate,
        endDate,
        customerId,
        searchQuery,
      ];
}

class FetchInvoiceDetailsEvent extends InvoiceEvent {
  final String invoiceId;

  const FetchInvoiceDetailsEvent(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

class GenerateNextInvoiceNumberEvent extends InvoiceEvent {
  final String businessId;
  final String? prefix;

  const GenerateNextInvoiceNumberEvent({required this.businessId, this.prefix});

  @override
  List<Object?> get props => [businessId, prefix];
}

class CreateInvoiceEvent extends InvoiceEvent {
  final InvoiceEntity invoice;
  final List<InvoiceItemEntity> items;

  const CreateInvoiceEvent({required this.invoice, required this.items});

  @override
  List<Object?> get props => [invoice, items];
}

class UpdateInvoiceEvent extends InvoiceEvent {
  final InvoiceEntity invoice;
  final List<InvoiceItemEntity> items;

  const UpdateInvoiceEvent({required this.invoice, required this.items});

  @override
  List<Object?> get props => [invoice, items];
}

class CancelInvoiceEvent extends InvoiceEvent {
  final String invoiceId;
  final String businessId;

  const CancelInvoiceEvent({required this.invoiceId, required this.businessId});

  @override
  List<Object?> get props => [invoiceId, businessId];
}

class DeleteInvoiceEvent extends InvoiceEvent {
  final String invoiceId;
  final String businessId;

  const DeleteInvoiceEvent({required this.invoiceId, required this.businessId});

  @override
  List<Object?> get props => [invoiceId, businessId];
}

// STATES
abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final String statusFilter;
  final String? searchQuery;

  const InvoiceLoaded({
    required this.invoices,
    this.statusFilter = 'all',
    this.searchQuery,
  });

  @override
  List<Object?> get props => [invoices, statusFilter, searchQuery];
}

class InvoiceDetailLoaded extends InvoiceState {
  final InvoiceEntity invoice;

  const InvoiceDetailLoaded(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class NextInvoiceNumberGenerated extends InvoiceState {
  final String invoiceNumber;
  final int sequenceNumber;

  const NextInvoiceNumberGenerated({
    required this.invoiceNumber,
    required this.sequenceNumber,
  });

  @override
  List<Object?> get props => [invoiceNumber, sequenceNumber];
}

class InvoiceActionSuccess extends InvoiceState {
  final String message;
  final InvoiceEntity? invoice;

  const InvoiceActionSuccess(this.message, {this.invoice});

  @override
  List<Object?> get props => [message, invoice];
}

class InvoiceError extends InvoiceState {
  final String message;

  const InvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository repository;

  InvoiceBloc({required this.repository}) : super(InvoiceInitial()) {
    on<FetchInvoicesEvent>(_onFetchInvoices);
    on<FetchInvoiceDetailsEvent>(_onFetchDetails);
    on<GenerateNextInvoiceNumberEvent>(_onGenerateNextNumber);
    on<CreateInvoiceEvent>(_onCreateInvoice);
    on<UpdateInvoiceEvent>(_onUpdateInvoice);
    on<CancelInvoiceEvent>(_onCancelInvoice);
    on<DeleteInvoiceEvent>(_onDeleteInvoice);
  }

  Future<void> _onFetchInvoices(
    FetchInvoicesEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final invoices = await repository.getInvoices(
        event.businessId,
        statusFilter: event.statusFilter,
        startDate: event.startDate,
        endDate: event.endDate,
        customerId: event.customerId,
        searchQuery: event.searchQuery,
      );
      emit(InvoiceLoaded(
        invoices: invoices,
        statusFilter: event.statusFilter ?? 'all',
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onFetchDetails(
    FetchInvoiceDetailsEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final invoice = await repository.getInvoiceById(event.invoiceId);
      emit(InvoiceDetailLoaded(invoice));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGenerateNextNumber(
    GenerateNextInvoiceNumberEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      final res = await repository.generateNextInvoiceNumber(
        event.businessId,
        prefix: event.prefix,
      );
      emit(NextInvoiceNumberGenerated(
        invoiceNumber: res['invoice_number'] as String,
        sequenceNumber: (res['sequence_number'] as num).toInt(),
      ));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateInvoice(
    CreateInvoiceEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final created = await repository.createInvoice(event.invoice, event.items);
      emit(InvoiceActionSuccess('Invoice created successfully', invoice: created));
      add(FetchInvoicesEvent(businessId: event.invoice.businessId));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateInvoice(
    UpdateInvoiceEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final updated = await repository.updateInvoice(event.invoice, event.items);
      emit(InvoiceActionSuccess('Invoice updated successfully', invoice: updated));
      add(FetchInvoicesEvent(businessId: event.invoice.businessId));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancelInvoice(
    CancelInvoiceEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      await repository.updateInvoiceStatus(event.invoiceId, 'cancelled', 'unpaid');
      emit(const InvoiceActionSuccess('Invoice cancelled successfully'));
      add(FetchInvoicesEvent(businessId: event.businessId));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteInvoice(
    DeleteInvoiceEvent event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      await repository.deleteInvoice(event.invoiceId);
      emit(const InvoiceActionSuccess('Invoice deleted successfully'));
      add(FetchInvoicesEvent(businessId: event.businessId));
    } catch (e) {
      emit(InvoiceError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
