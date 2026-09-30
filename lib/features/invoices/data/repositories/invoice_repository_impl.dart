import 'package:bizos/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:bizos/features/invoices/data/models/invoice_item_model.dart';
import 'package:bizos/features/invoices/data/models/invoice_model.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_entity.dart';
import 'package:bizos/features/invoices/domain/entities/invoice_item_entity.dart';
import 'package:bizos/features/invoices/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDatasource remoteDatasource;

  InvoiceRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Map<String, dynamic>> generateNextInvoiceNumber(String businessId, {String? prefix}) {
    return remoteDatasource.generateNextInvoiceNumber(businessId, prefix: prefix);
  }

  @override
  Future<List<InvoiceEntity>> getInvoices(
    String businessId, {
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? searchQuery,
  }) {
    return remoteDatasource.getInvoices(
      businessId,
      statusFilter: statusFilter,
      startDate: startDate,
      endDate: endDate,
      customerId: customerId,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<InvoiceEntity> getInvoiceById(String id) {
    return remoteDatasource.getInvoiceById(id);
  }

  @override
  Future<InvoiceEntity> createInvoice(InvoiceEntity invoice, List<InvoiceItemEntity> items) {
    final model = InvoiceModel.fromEntity(invoice);
    final itemModels = items.map((i) => InvoiceItemModel.fromEntity(i)).toList();
    return remoteDatasource.createInvoice(model, itemModels);
  }

  @override
  Future<InvoiceEntity> updateInvoice(InvoiceEntity invoice, List<InvoiceItemEntity> items) {
    final model = InvoiceModel.fromEntity(invoice);
    final itemModels = items.map((i) => InvoiceItemModel.fromEntity(i)).toList();
    return remoteDatasource.updateInvoice(model, itemModels);
  }

  @override
  Future<void> updateInvoiceStatus(String invoiceId, String status, String paymentStatus) {
    return remoteDatasource.updateInvoiceStatus(invoiceId, status, paymentStatus);
  }

  @override
  Future<void> deleteInvoice(String id) {
    return remoteDatasource.deleteInvoice(id);
  }
}
