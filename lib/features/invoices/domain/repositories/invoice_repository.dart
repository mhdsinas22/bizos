import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';

abstract class InvoiceRepository {
  Future<Map<String, dynamic>> generateNextInvoiceNumber(String businessId, {String? prefix});
  Future<List<InvoiceEntity>> getInvoices(
    String businessId, {
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? searchQuery,
  });
  Future<InvoiceEntity> getInvoiceById(String id);
  Future<InvoiceEntity> createInvoice(InvoiceEntity invoice, List<InvoiceItemEntity> items);
  Future<InvoiceEntity> updateInvoice(InvoiceEntity invoice, List<InvoiceItemEntity> items);
  Future<void> updateInvoiceStatus(String invoiceId, String status, String paymentStatus);
  Future<void> deleteInvoice(String id);
}
