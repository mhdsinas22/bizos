import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/invoices/data/models/invoice_item_model.dart';
import 'package:bizos/features/invoices/data/models/invoice_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class InvoiceRemoteDatasource {
  Future<Map<String, dynamic>> generateNextInvoiceNumber(String businessId, {String? prefix});
  Future<List<InvoiceModel>> getInvoices(
    String businessId, {
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? searchQuery,
  });
  Future<InvoiceModel> getInvoiceById(String id);
  Future<InvoiceModel> createInvoice(InvoiceModel invoice, List<InvoiceItemModel> items);
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice, List<InvoiceItemModel> items);
  Future<void> updateInvoiceStatus(String invoiceId, String status, String paymentStatus);
  Future<void> deleteInvoice(String id);
}

class InvoiceRemoteDatasourceImpl implements InvoiceRemoteDatasource {
  final SupabaseClient supabaseClient;

  InvoiceRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>> generateNextInvoiceNumber(String businessId, {String? prefix}) async {
    try {
      final pPrefix = prefix ?? 'INV-';
      final response = await supabaseClient.rpc(
        'generate_next_invoice_number',
        params: {'p_business_id': businessId, 'p_prefix': pPrefix},
      );

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      // Fallback in-app counter query if RPC not yet deployed
      final maxRes = await supabaseClient
          .from('invoices')
          .select('sequence_number')
          .eq('business_id', businessId)
          .order('sequence_number', ascending: false)
          .limit(1)
          .maybeSingle();

      final nextSeq = (maxRes != null && maxRes['sequence_number'] != null)
          ? ((maxRes['sequence_number'] as num).toInt() + 1)
          : 1;
      final invNum = '$pPrefix${nextSeq.toString().padLeft(4, '0')}';

      return {
        'sequence_number': nextSeq,
        'invoice_number': invNum,
      };
    } catch (e) {
      // Safe fallback calculation
      return {
        'sequence_number': 1,
        'invoice_number': '${prefix ?? 'INV-'}0001',
      };
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoices(
    String businessId, {
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? searchQuery,
  }) async {
    try {
      if (businessId.trim().isEmpty) return [];

      var query = supabaseClient
          .from('invoices')
          .select('*, invoice_items(*), customers(*)')
          .eq('business_id', businessId);

      if (statusFilter != null && statusFilter.trim().isNotEmpty && statusFilter != 'all') {
        final s = statusFilter.trim().toLowerCase();
        query = query.eq('status', s);
      }

      if (customerId != null && customerId.trim().isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }

      if (startDate != null) {
        query = query.gte('invoice_date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('invoice_date', endDate.toIso8601String().split('T')[0]);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = '%${searchQuery.trim().toLowerCase()}%';
        query = query.or('invoice_number.ilike.$q,notes.ilike.$q');
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((row) => InvoiceModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch invoices: $e');
    }
  }

  @override
  Future<InvoiceModel> getInvoiceById(String id) async {
    try {
      final response = await supabaseClient
          .from('invoices')
          .select('*, invoice_items(*), customers(*)')
          .eq('id', id)
          .single();

      return InvoiceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch invoice details: $e');
    }
  }

  @override
  Future<InvoiceModel> createInvoice(InvoiceModel invoice, List<InvoiceItemModel> items) async {
    try {
      final invoiceData = invoice.toJson();
      final createdInvoice = await supabaseClient
          .from('invoices')
          .insert(invoiceData)
          .select()
          .single();

      final invoiceId = createdInvoice['id'] as String;

      // Insert line items
      if (items.isNotEmpty) {
        final itemsData = items.map((i) => i.toJson(parentInvoiceId: invoiceId)).toList();
        await supabaseClient.from('invoice_items').insert(itemsData);
      }

      // Sync customer receivable in business_money_transactions if outstanding > 0 & not draft/cancelled
      if (invoice.balanceAmount > 0 && invoice.status != 'draft' && invoice.status != 'cancelled') {
        await _syncMoneyToReceive(
          businessId: invoice.businessId,
          customerName: invoice.customerNameSnapshot,
          customerPhone: invoice.customerPhoneSnapshot,
          amount: invoice.grandTotal,
          paidAmount: invoice.paidAmount,
          balanceAmount: invoice.balanceAmount,
          dueDate: invoice.dueDate,
          notes: 'Invoice #${invoice.invoiceNumber}',
        );
      }

      return getInvoiceById(invoiceId);
    } catch (e) {
      throw ServerException('Failed to create invoice: $e');
    }
  }

  @override
  Future<InvoiceModel> updateInvoice(InvoiceModel invoice, List<InvoiceItemModel> items) async {
    try {
      final invoiceData = invoice.toJson();
      await supabaseClient
          .from('invoices')
          .update(invoiceData)
          .eq('id', invoice.id);

      // Re-insert line items (delete old, insert new)
      await supabaseClient.from('invoice_items').delete().eq('invoice_id', invoice.id);

      if (items.isNotEmpty) {
        final itemsData = items.map((i) => i.toJson(parentInvoiceId: invoice.id)).toList();
        await supabaseClient.from('invoice_items').insert(itemsData);
      }

      // Sync customer receivable in business_money_transactions
      if (invoice.status != 'draft' && invoice.status != 'cancelled') {
        await _syncMoneyToReceive(
          businessId: invoice.businessId,
          customerName: invoice.customerNameSnapshot,
          customerPhone: invoice.customerPhoneSnapshot,
          amount: invoice.grandTotal,
          paidAmount: invoice.paidAmount,
          balanceAmount: invoice.balanceAmount,
          dueDate: invoice.dueDate,
          notes: 'Invoice #${invoice.invoiceNumber}',
        );
      }

      return getInvoiceById(invoice.id);
    } catch (e) {
      throw ServerException('Failed to update invoice: $e');
    }
  }

  @override
  Future<void> updateInvoiceStatus(String invoiceId, String status, String paymentStatus) async {
    try {
      await supabaseClient.from('invoices').update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', invoiceId);
    } catch (e) {
      throw ServerException('Failed to update invoice status: $e');
    }
  }

  @override
  Future<void> deleteInvoice(String id) async {
    try {
      await supabaseClient.from('invoices').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete invoice: $e');
    }
  }

  Future<void> _syncMoneyToReceive({
    required String businessId,
    required String customerName,
    required String customerPhone,
    required double amount,
    required double paidAmount,
    required double balanceAmount,
    DateTime? dueDate,
    required String notes,
  }) async {
    try {
      // Find existing transaction by person_name and phone
      final existing = await supabaseClient
          .from('business_money_transactions')
          .select()
          .eq('business_id', businessId)
          .eq('transaction_type', 'receive')
          .eq('person_name', customerName)
          .maybeSingle();

      final statusStr = balanceAmount <= 0
          ? 'Completed'
          : (paidAmount > 0 ? 'Partial' : 'Pending');

      if (existing != null) {
        final existingId = existing['id'] as String;
        await supabaseClient.from('business_money_transactions').update({
          'amount': amount,
          'paid_amount': paidAmount,
          'balance_amount': balanceAmount,
          'status': statusStr,
          'notes': notes,
          'due_date': dueDate?.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', existingId);
      } else {
        await supabaseClient.from('business_money_transactions').insert({
          'business_id': businessId,
          'transaction_type': 'receive',
          'person_name': customerName,
          'phone': customerPhone,
          'amount': amount,
          'paid_amount': paidAmount,
          'balance_amount': balanceAmount,
          'status': statusStr,
          'notes': notes,
          'due_date': dueDate?.toUtc().toIso8601String(),
        });
      }
    } catch (_) {
      // Suppress secondary sync errors to preserve primary invoice flow
    }
  }
}
