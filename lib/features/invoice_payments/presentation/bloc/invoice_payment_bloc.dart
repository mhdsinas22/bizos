import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/invoice_payments/domain/entities/invoice_payment_entity.dart';
import 'package:bizos/features/invoice_payments/domain/repositories/invoice_payment_repository.dart';

// EVENTS
abstract class InvoicePaymentEvent extends Equatable {
  const InvoicePaymentEvent();
  @override
  List<Object?> get props => [];
}

class FetchPaymentsForInvoiceEvent extends InvoicePaymentEvent {
  final String invoiceId;

  const FetchPaymentsForInvoiceEvent(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

class RecordInvoicePaymentEvent extends InvoicePaymentEvent {
  final InvoicePaymentEntity payment;

  const RecordInvoicePaymentEvent(this.payment);

  @override
  List<Object?> get props => [payment];
}

class DeleteInvoicePaymentEvent extends InvoicePaymentEvent {
  final String paymentId;
  final String invoiceId;
  final String businessId;

  const DeleteInvoicePaymentEvent({
    required this.paymentId,
    required this.invoiceId,
    required this.businessId,
  });

  @override
  List<Object?> get props => [paymentId, invoiceId, businessId];
}

// STATES
abstract class InvoicePaymentState extends Equatable {
  const InvoicePaymentState();
  @override
  List<Object?> get props => [];
}

class InvoicePaymentInitial extends InvoicePaymentState {}

class InvoicePaymentLoading extends InvoicePaymentState {}

class InvoicePaymentLoaded extends InvoicePaymentState {
  final List<InvoicePaymentEntity> payments;

  const InvoicePaymentLoaded(this.payments);

  @override
  List<Object?> get props => [payments];
}

class InvoicePaymentSuccess extends InvoicePaymentState {
  final String message;
  final InvoicePaymentEntity payment;

  const InvoicePaymentSuccess({required this.message, required this.payment});

  @override
  List<Object?> get props => [message, payment];
}

class InvoicePaymentError extends InvoicePaymentState {
  final String message;

  const InvoicePaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLOC
class InvoicePaymentBloc extends Bloc<InvoicePaymentEvent, InvoicePaymentState> {
  final InvoicePaymentRepository repository;

  InvoicePaymentBloc({required this.repository}) : super(InvoicePaymentInitial()) {
    on<FetchPaymentsForInvoiceEvent>(_onFetch);
    on<RecordInvoicePaymentEvent>(_onRecord);
    on<DeleteInvoicePaymentEvent>(_onDelete);
  }

  Future<void> _onFetch(
    FetchPaymentsForInvoiceEvent event,
    Emitter<InvoicePaymentState> emit,
  ) async {
    emit(InvoicePaymentLoading());
    try {
      final payments = await repository.getPaymentsForInvoice(event.invoiceId);
      emit(InvoicePaymentLoaded(payments));
    } catch (e) {
      emit(InvoicePaymentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRecord(
    RecordInvoicePaymentEvent event,
    Emitter<InvoicePaymentState> emit,
  ) async {
    emit(InvoicePaymentLoading());
    try {
      final recorded = await repository.recordPayment(event.payment);
      emit(InvoicePaymentSuccess(message: 'Payment of ₹${event.payment.amount} recorded!', payment: recorded));
      add(FetchPaymentsForInvoiceEvent(event.payment.invoiceId));
    } catch (e) {
      emit(InvoicePaymentError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDelete(
    DeleteInvoicePaymentEvent event,
    Emitter<InvoicePaymentState> emit,
  ) async {
    emit(InvoicePaymentLoading());
    try {
      await repository.deletePayment(event.paymentId, event.invoiceId, event.businessId);
      add(FetchPaymentsForInvoiceEvent(event.invoiceId));
    } catch (e) {
      emit(InvoicePaymentError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
