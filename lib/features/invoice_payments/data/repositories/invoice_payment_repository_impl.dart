import 'package:bizos/features/invoice_payments/data/datasources/invoice_payment_remote_datasource.dart';
import 'package:bizos/features/invoice_payments/data/models/invoice_payment_model.dart';
import 'package:bizos/features/invoice_payments/domain/entities/invoice_payment_entity.dart';
import 'package:bizos/features/invoice_payments/domain/repositories/invoice_payment_repository.dart';

class InvoicePaymentRepositoryImpl implements InvoicePaymentRepository {
  final InvoicePaymentRemoteDatasource remoteDatasource;

  InvoicePaymentRepositoryImpl({required this.remoteDatasource});

  @override
  Future<List<InvoicePaymentEntity>> getPaymentsForInvoice(String invoiceId) {
    return remoteDatasource.getPaymentsForInvoice(invoiceId);
  }

  @override
  Future<InvoicePaymentEntity> recordPayment(InvoicePaymentEntity payment) {
    final model = InvoicePaymentModel.fromEntity(payment);
    return remoteDatasource.recordPayment(model);
  }

  @override
  Future<void> deletePayment(String paymentId, String invoiceId, String businessId) {
    return remoteDatasource.deletePayment(paymentId, invoiceId, businessId);
  }
}
