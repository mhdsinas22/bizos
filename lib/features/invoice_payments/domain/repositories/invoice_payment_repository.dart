import 'package:bizos/features/invoice_payments/domain/entities/invoice_payment_entity.dart';

abstract class InvoicePaymentRepository {
  Future<List<InvoicePaymentEntity>> getPaymentsForInvoice(String invoiceId);
  Future<InvoicePaymentEntity> recordPayment(InvoicePaymentEntity payment);
  Future<void> deletePayment(String paymentId, String invoiceId, String businessId);
}
