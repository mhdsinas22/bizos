import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/invoice_payments/data/models/invoice_payment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class InvoicePaymentRemoteDatasource {
  Future<List<InvoicePaymentModel>> getPaymentsForInvoice(String invoiceId);
  Future<InvoicePaymentModel> recordPayment(InvoicePaymentModel payment);
  Future<void> deletePayment(String paymentId, String invoiceId, String businessId);
}

class InvoicePaymentRemoteDatasourceImpl implements InvoicePaymentRemoteDatasource {
  final SupabaseClient supabaseClient;

  InvoicePaymentRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<InvoicePaymentModel>> getPaymentsForInvoice(String invoiceId) async {
    try {
      final response = await supabaseClient
          .from('invoice_payments')
          .select()
          .eq('invoice_id', invoiceId)
          .order('payment_date', ascending: false);

      return (response as List<dynamic>)
          .map((row) => InvoicePaymentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch invoice payments: $e');
    }
  }

  @override
  Future<InvoicePaymentModel> recordPayment(InvoicePaymentModel payment) async {
    try {
      // 1. Fetch current invoice details to calculate new paid and balance amounts
      final invoiceRes = await supabaseClient
          .from('invoices')
          .select()
          .eq('id', payment.invoiceId)
          .single();

      final grandTotal = (invoiceRes['total_amount'] as num?)?.toDouble() ?? (invoiceRes['grand_total'] as num?)?.toDouble() ?? 0.0;
      final currentPaid = (invoiceRes['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final currentBalance = (invoiceRes['balance_amount'] as num?)?.toDouble() ?? grandTotal;
      final invNumber = invoiceRes['invoice_number'] as String? ?? '';
      final customerName = invoiceRes['customer_name_snapshot'] as String? ?? '';

      // Validate payment amount does not exceed current outstanding balance
      if (payment.amount <= 0) {
        throw Exception('Payment amount must be greater than 0');
      }
      if (payment.amount > (currentBalance + 0.01)) {
        throw Exception('Payment amount (₹${payment.amount}) cannot exceed balance due (₹$currentBalance)');
      }

      final newPaid = currentPaid + payment.amount;
      final newBalance = (grandTotal - newPaid) > 0 ? (grandTotal - newPaid) : 0.0;

      final newStatus = newBalance <= 0
          ? 'paid'
          : (newPaid > 0 ? 'partially_paid' : 'sent');

      // 2. Create entry in incomes table for actual cash income received
      String? incomeId;
      try {
        final incomeData = {
          'business_id': payment.businessId,
          'amount': payment.amount,
          'category': 'Invoice Payment',
          'payment_method': payment.paymentMethod,
          'description': 'Payment for Invoice #$invNumber ($customerName)',
          'income_date': payment.paymentDate.toIso8601String(),
          'created_by_user_id': payment.createdByUserId,
        };
        final incRes = await supabaseClient
            .from('incomes')
            .insert(incomeData)
            .select()
            .single();

        incomeId = incRes['id'] as String?;
      } catch (_) {
        // Fallback if incomes insert fails
      }

      // 3. Insert payment record
      final paymentData = payment.copyWith(incomeId: incomeId).toJson();
      final createdPaymentRes = await supabaseClient
          .from('invoice_payments')
          .insert(paymentData)
          .select()
          .single();

      final createdPayment = InvoicePaymentModel.fromJson(createdPaymentRes);

      // 4. Update Invoice status & paid/balance amounts
      await supabaseClient.from('invoices').update({
        'paid_amount': newPaid,
        'balance_amount': newBalance,
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', payment.invoiceId);

      // 5. Sync Money Management receivable transaction & history
      await _syncMoneyManagementAfterPayment(
        businessId: payment.businessId,
        customerName: customerName,
        paymentAmount: payment.amount,
        newBalance: newBalance,
        paymentMethod: payment.paymentMethod,
        invNumber: invNumber,
      );

      return createdPayment;
    } catch (e) {
      throw ServerException('Failed to record payment: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Future<void> deletePayment(String paymentId, String invoiceId, String businessId) async {
    try {
      final paymentRes = await supabaseClient
          .from('invoice_payments')
          .select()
          .eq('id', paymentId)
          .single();

      final amount = (paymentRes['amount'] as num?)?.toDouble() ?? 0.0;
      final incomeId = paymentRes['income_id'] as String?;

      // Delete linked income record if present
      if (incomeId != null && incomeId.isNotEmpty) {
        await supabaseClient.from('incomes').delete().eq('id', incomeId);
      }

      // Delete payment record
      await supabaseClient.from('invoice_payments').delete().eq('id', paymentId);

      // Re-calculate invoice paid & balance amounts
      final invoiceRes = await supabaseClient
          .from('invoices')
          .select()
          .eq('id', invoiceId)
          .single();

      final grandTotal = (invoiceRes['total_amount'] as num?)?.toDouble() ?? (invoiceRes['grand_total'] as num?)?.toDouble() ?? 0.0;
      final currentPaid = (invoiceRes['paid_amount'] as num?)?.toDouble() ?? 0.0;

      final newPaid = (currentPaid - amount) > 0 ? (currentPaid - amount) : 0.0;
      final newBalance = grandTotal - newPaid;

      final newStatus = newBalance <= 0
          ? 'paid'
          : (newPaid > 0 ? 'partially_paid' : 'sent');

      await supabaseClient.from('invoices').update({
        'paid_amount': newPaid,
        'balance_amount': newBalance,
        'status': newStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', invoiceId);
    } catch (e) {
      throw ServerException('Failed to delete payment: $e');
    }
  }

  Future<void> _syncMoneyManagementAfterPayment({
    required String businessId,
    required String customerName,
    required double paymentAmount,
    required double newBalance,
    required String paymentMethod,
    required String invNumber,
  }) async {
    try {
      final existing = await supabaseClient
          .from('business_money_transactions')
          .select()
          .eq('business_id', businessId)
          .eq('transaction_type', 'receive')
          .eq('person_name', customerName)
          .maybeSingle();

      if (existing != null) {
        final existingId = existing['id'] as String;
        final currentPaid = (existing['paid_amount'] as num?)?.toDouble() ?? 0.0;
        final updatedPaid = currentPaid + paymentAmount;
        final statusStr = newBalance <= 0
            ? 'Completed'
            : (updatedPaid > 0 ? 'Partial' : 'Pending');

        await supabaseClient.from('business_money_transactions').update({
          'paid_amount': updatedPaid,
          'balance_amount': newBalance,
          'status': statusStr,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', existingId);

        // Record history event in business_money_transaction_history
        await supabaseClient.from('business_money_transaction_history').insert({
          'transaction_id': existingId,
          'business_id': businessId,
          'event_type': 'payment',
          'amount': paymentAmount,
          'balance_after': newBalance,
          'payment_method': paymentMethod,
          'notes': 'Received payment for Invoice #$invNumber',
        });
      }
    } catch (_) {
      // Suppress secondary sync errors
    }
  }
}
