import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/money_management/data/models/debt_model.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_model.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_history_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MoneyManagementRemoteDatasource {
  Stream<List<MoneyTransactionModel>> watchPersonalTransactions(String userId);
  Stream<List<MoneyTransactionModel>> watchBusinessTransactions(
    String businessId,
  );
  Future<MoneyTransactionModel> addTransaction(
    MoneyTransactionModel transaction,
    bool isPersonal,
  );
  Future<MoneyTransactionModel> addDebt(DebtModel debt, bool isPersonal);
  Future<MoneyTransactionModel> createDebt(DebtModel debt, bool isPersonal);
  Future<void> updateTransaction(
    MoneyTransactionModel transaction,
    bool isPersonal,
  );
  Future<MoneyTransactionModel?> getTransactionById(
    String id,
    bool isPersonal,
  );
  Future<MoneyTransactionModel?> deleteTransaction(String id, bool isPersonal);

  // History Methods
  Future<List<MoneyTransactionHistoryModel>> getTransactionHistory({
    required String transactionId,
    required bool isPersonal,
    required int limit,
    required int offset,
    String? filterEventType,
    String? searchQuery,
    bool ascending = false,
  });

  Future<MoneyTransactionHistoryModel> addPaymentHistory({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  });

  Future<MoneyTransactionHistoryModel> addAdjustmentHistory({
    required String transactionId,
    required double amount,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  });

  Future<MoneyTransactionHistoryModel> addReminderHistory({
    required String transactionId,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  });

  Future<MoneyTransactionHistoryModel> updateHistoryItem({
    required MoneyTransactionHistoryModel historyItem,
    required bool isPersonal,
  });

  Future<void> deleteHistoryItem({
    required String historyId,
    required String transactionId,
    required bool isPersonal,
  });
}

class MoneyManagementRemoteDatasourceImpl
    implements MoneyManagementRemoteDatasource {
  final SupabaseClient supabaseClient;

  MoneyManagementRemoteDatasourceImpl({required this.supabaseClient});

  String _getParentTable(bool isPersonal) => isPersonal
      ? 'personal_money_transactions'
      : 'business_money_transactions';

  String _getHistoryTable(bool isPersonal) => isPersonal
      ? 'personal_money_transaction_history'
      : 'business_money_transaction_history';

  @override
  Stream<List<MoneyTransactionModel>> watchPersonalTransactions(String userId) {
    try {
      return supabaseClient
          .from('personal_money_transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((list) {
            final models = list
                .map((item) => MoneyTransactionModel.fromJson(item))
                .toList();
            models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return models;
          });
    } catch (e) {
      throw ServerException('Failed to watch personal transactions: $e');
    }
  }

  @override
  Stream<List<MoneyTransactionModel>> watchBusinessTransactions(
    String businessId,
  ) {
    try {
      return supabaseClient
          .from('business_money_transactions')
          .stream(primaryKey: ['id'])
          .eq('business_id', businessId)
          .map((list) {
            final models = list
                .map((item) => MoneyTransactionModel.fromJson(item))
                .toList();
            models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return models;
          });
    } catch (e) {
      throw ServerException('Failed to watch business transactions: $e');
    }
  }

  Future<MoneyTransactionModel?> _findExistingParentTransaction({
    String? transactionId,
    required String personName,
    required String phone,
    required String transactionType,
    required bool isPersonal,
    String? userId,
    String? businessId,
  }) async {
    final parentTable = _getParentTable(isPersonal);

    // 1. Check by explicit transactionId if provided
    if (transactionId != null && transactionId.isNotEmpty) {
      final parentRes = await supabaseClient
          .from(parentTable)
          .select()
          .eq('id', transactionId)
          .maybeSingle();

      if (parentRes != null) {
        return MoneyTransactionModel.fromJson(parentRes);
      }
    }

    // 2. Lookup by customer identity (person_name, phone, transactionType, business_id/user_id)
    if (personName.trim().isNotEmpty) {
      dynamic query = supabaseClient
          .from(parentTable)
          .select()
          .eq('transaction_type', transactionType)
          .ilike('person_name', personName.trim());

      if (isPersonal && userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      } else if (!isPersonal && businessId != null && businessId.isNotEmpty) {
        query = query.eq('business_id', businessId);
      }

      if (phone.trim().isNotEmpty) {
        query = query.eq('phone', phone.trim());
      }

      final resList = await query.order('created_at', ascending: false);
      if (resList is List && resList.isNotEmpty) {
        return MoneyTransactionModel.fromJson(resList.first);
      }

      // Fallback: If phone was provided but returned no match, search by person_name alone
      if (phone.trim().isNotEmpty) {
        dynamic nameOnlyQuery = supabaseClient
            .from(parentTable)
            .select()
            .eq('transaction_type', transactionType)
            .ilike('person_name', personName.trim());

        if (isPersonal && userId != null && userId.isNotEmpty) {
          nameOnlyQuery = nameOnlyQuery.eq('user_id', userId);
        } else if (!isPersonal && businessId != null && businessId.isNotEmpty) {
          nameOnlyQuery = nameOnlyQuery.eq('business_id', businessId);
        }

        final fallbackList = await nameOnlyQuery.order('created_at', ascending: false);
        if (fallbackList is List && fallbackList.isNotEmpty) {
          return MoneyTransactionModel.fromJson(fallbackList.first);
        }
      }
    }

    return null;
  }

  @override
  Future<MoneyTransactionModel> addTransaction(
    MoneyTransactionModel transaction,
    bool isPersonal,
  ) async {
    try {
      final parentTable = _getParentTable(isPersonal);
      final historyTable = _getHistoryTable(isPersonal);

      final existingParent = await _findExistingParentTransaction(
        transactionId: transaction.id.isNotEmpty ? transaction.id : null,
        personName: transaction.personName,
        phone: transaction.phone,
        transactionType: transaction.transactionType,
        isPersonal: isPersonal,
        userId: transaction.userId,
        businessId: transaction.businessId,
      );

      if (existingParent != null) {
        // Customer already exists -> update existing parent and insert history record
        final double newTotalAmount =
            ((existingParent.amount + transaction.amount) * 100).roundToDouble() / 100.0;
        final double newPaidAmount =
            ((existingParent.paidAmount + transaction.paidAmount) * 100).roundToDouble() / 100.0;
        double newBalanceAmount = newTotalAmount - newPaidAmount;
        if (newBalanceAmount < 0) newBalanceAmount = 0.0;
        newBalanceAmount = (newBalanceAmount * 100).roundToDouble() / 100.0;

        final updateData = <String, dynamic>{
          'amount': newTotalAmount,
          'paid_amount': newPaidAmount,
          'balance_amount': newBalanceAmount,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'status': newBalanceAmount > 0 ? 'Pending' : 'Completed',
        };
        if (transaction.dueDate != null) {
          updateData['due_date'] = transaction.dueDate!.toUtc().toIso8601String();
        }
        if (transaction.phone.isNotEmpty && existingParent.phone.isEmpty) {
          updateData['phone'] = transaction.phone;
        }

        await supabaseClient
            .from(parentTable)
            .update(updateData)
            .eq('id', existingParent.id);

        final historyData = <String, dynamic>{
          'transaction_id': existingParent.id,
          'event_type': 'debt_added',
          'amount': transaction.amount,
          'balance_after': newBalanceAmount,
          'notes': transaction.notes.isNotEmpty
              ? transaction.notes
              : (transaction.transactionType == 'receive'
                  ? 'Receivable Added'
                  : 'Debt Added'),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (isPersonal && transaction.userId != null) {
          historyData['user_id'] = transaction.userId;
        }
        if (!isPersonal && transaction.businessId != null) {
          historyData['business_id'] = transaction.businessId;
        }

        await supabaseClient.from(historyTable).insert(historyData);

        if (transaction.paidAmount > 0) {
          final paymentHistoryData = <String, dynamic>{
            'transaction_id': existingParent.id,
            'event_type': 'payment',
            'amount': transaction.paidAmount,
            'balance_after': newBalanceAmount,
            'payment_method': 'Cash',
            'notes': 'Initial Payment',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          };
          if (isPersonal && transaction.userId != null) {
            paymentHistoryData['user_id'] = transaction.userId;
          }
          if (!isPersonal && transaction.businessId != null) {
            paymentHistoryData['business_id'] = transaction.businessId;
          }
          await supabaseClient.from(historyTable).insert(paymentHistoryData);
        }

        await _recalculateParentTotals(
          transactionId: existingParent.id,
          isPersonal: isPersonal,
        );

        final updatedParentRes = await supabaseClient
            .from(parentTable)
            .select()
            .eq('id', existingParent.id)
            .single();
        return MoneyTransactionModel.fromJson(updatedParentRes);
      }

      // If no existing parent transaction -> Create brand new parent & insert history 'debt_created'
      final mapData = transaction.toJson();
      if (transaction.id.isEmpty) {
        mapData.remove('id');
      }

      final response = await supabaseClient
          .from(parentTable)
          .insert(mapData)
          .select()
          .single();
      final createdTransaction = MoneyTransactionModel.fromJson(response);

      // Create initial debt_created history item
      final historyCreatedData = <String, dynamic>{
        'transaction_id': createdTransaction.id,
        'event_type': 'debt_created',
        'amount': createdTransaction.amount,
        'balance_after': createdTransaction.balanceAmount,
        'notes': createdTransaction.notes.isNotEmpty
            ? createdTransaction.notes
            : (createdTransaction.transactionType == 'receive'
                ? 'Receivable Created'
                : 'Debt Created'),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (isPersonal && createdTransaction.userId != null) {
        historyCreatedData['user_id'] = createdTransaction.userId;
      }
      if (!isPersonal && createdTransaction.businessId != null) {
        historyCreatedData['business_id'] = createdTransaction.businessId;
      }

      await supabaseClient.from(historyTable).insert(historyCreatedData);

      if (createdTransaction.paidAmount > 0) {
        final paymentHistoryData = <String, dynamic>{
          'transaction_id': createdTransaction.id,
          'event_type': 'payment',
          'amount': createdTransaction.paidAmount,
          'balance_after': createdTransaction.balanceAmount,
          'payment_method': 'Cash',
          'notes': 'Initial Payment',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (isPersonal && createdTransaction.userId != null) {
          paymentHistoryData['user_id'] = createdTransaction.userId;
        }
        if (!isPersonal && createdTransaction.businessId != null) {
          paymentHistoryData['business_id'] = createdTransaction.businessId;
        }
        await supabaseClient.from(historyTable).insert(paymentHistoryData);
      }

      return createdTransaction;
    } catch (e) {
      throw ServerException('Failed to add transaction: $e');
    }
  }

  @override
  Future<MoneyTransactionModel> addDebt(DebtModel debt, bool isPersonal) async {
    try {
      final parentTable = _getParentTable(isPersonal);
      final historyTable = _getHistoryTable(isPersonal);

      final activeParent = await _findExistingParentTransaction(
        transactionId: debt.transactionId,
        personName: debt.personName,
        phone: debt.phone,
        transactionType: debt.transactionType,
        isPersonal: isPersonal,
        userId: debt.userId,
        businessId: debt.businessId,
      );

      // STEP 2: IF EXISTING PARENT TRANSACTION EXISTS -> Update parent & insert history 'debt_added'
      if (activeParent != null) {
        final double newTotalAmount =
            (activeParent.amount * 100 + debt.amount * 100).roundToDouble() / 100.0;
        final double newBalanceAmount =
            (activeParent.balanceAmount * 100 + debt.amount * 100).roundToDouble() / 100.0;

        final updateData = <String, dynamic>{
          'amount': newTotalAmount,
          'balance_amount': newBalanceAmount,
          'due_date': debt.dueDate.toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'status': newBalanceAmount > 0 ? 'Pending' : 'Completed',
        };

        await supabaseClient
            .from(parentTable)
            .update(updateData)
            .eq('id', activeParent.id);

        final historyData = debt.toHistoryJson(
          parentTransactionId: activeParent.id,
          eventType: 'debt_added',
          balanceAfter: newBalanceAmount,
        );

        await supabaseClient.from(historyTable).insert(historyData);

        await _recalculateParentTotals(
          transactionId: activeParent.id,
          isPersonal: isPersonal,
        );

        final updatedParentRes = await supabaseClient
            .from(parentTable)
            .select()
            .eq('id', activeParent.id)
            .single();
        return MoneyTransactionModel.fromJson(updatedParentRes);
      }

      // STEP 3: IF NO ACTIVE TRANSACTION EXISTS -> Create brand new parent & insert history 'debt_created'
      final mapData = debt.toTransactionJson();
      String? insertedId;
      try {
        final response = await supabaseClient
            .from(parentTable)
            .insert(mapData)
            .select()
            .single();
        final createdTransaction = MoneyTransactionModel.fromJson(response);
        insertedId = createdTransaction.id;

        final historyData = debt.toHistoryJson(
          parentTransactionId: createdTransaction.id,
          eventType: 'debt_created',
          balanceAfter: createdTransaction.amount,
        );

        await supabaseClient.from(historyTable).insert(historyData);
        return createdTransaction;
      } catch (e) {
        if (insertedId != null && insertedId.isNotEmpty) {
          try {
            await supabaseClient.from(parentTable).delete().eq('id', insertedId);
          } catch (_) {}
        }
        rethrow;
      }
    } catch (e) {
      throw ServerException('Failed to add debt: $e');
    }
  }

  @override
  Future<MoneyTransactionModel> createDebt(
    DebtModel debt,
    bool isPersonal,
  ) async {
    return addDebt(debt, isPersonal);
  }

  @override
  Future<void> updateTransaction(
    MoneyTransactionModel transaction,
    bool isPersonal,
  ) async {
    try {
      final parentTable = _getParentTable(isPersonal);
      final historyTable = _getHistoryTable(isPersonal);

      final mapData = {
        'person_name': transaction.personName,
        'phone': transaction.phone,
        'amount': transaction.amount,
        'paid_amount': transaction.paidAmount,
        'balance_amount': transaction.balanceAmount,
        'due_date': transaction.dueDate?.toIso8601String(),
        'notes': transaction.notes,
        'status': transaction.status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await supabaseClient
          .from(parentTable)
          .update(mapData)
          .eq('id', transaction.id);

      // Log status_changed history if status was updated
      final historyData = <String, dynamic>{
        'transaction_id': transaction.id,
        'event_type': 'status_changed',
        'amount': transaction.balanceAmount,
        'balance_after': transaction.balanceAmount,
        'notes': 'Transaction updated: ${transaction.notes}',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (isPersonal && transaction.userId != null) {
        historyData['user_id'] = transaction.userId;
      }
      if (!isPersonal && transaction.businessId != null) {
        historyData['business_id'] = transaction.businessId;
      }
      await supabaseClient.from(historyTable).insert(historyData);
    } catch (e) {
      throw ServerException('Failed to update transaction: $e');
    }
  }

  @override
  Future<MoneyTransactionModel?> getTransactionById(
    String id,
    bool isPersonal,
  ) async {
    try {
      final parentTable = _getParentTable(isPersonal);
      final response = await supabaseClient
          .from(parentTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) {
        return MoneyTransactionModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to get transaction: $e');
    }
  }

  @override
  Future<MoneyTransactionModel?> deleteTransaction(
    String id,
    bool isPersonal,
  ) async {
    try {
      final parentTable = _getParentTable(isPersonal);
      final historyTable = _getHistoryTable(isPersonal);

      final response = await supabaseClient
          .from(parentTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response != null) {
        final model = MoneyTransactionModel.fromJson(response);
        // Delete history records first
        await supabaseClient
            .from(historyTable)
            .delete()
            .eq('transaction_id', id);
        // Delete parent transaction record
        await supabaseClient.from(parentTable).delete().eq('id', id);
        return model;
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to delete transaction: $e');
    }
  }

  @override
  Future<List<MoneyTransactionHistoryModel>> getTransactionHistory({
    required String transactionId,
    required bool isPersonal,
    required int limit,
    required int offset,
    String? filterEventType,
    String? searchQuery,
    bool ascending = false,
  }) async {
    try {
      final historyTable = _getHistoryTable(isPersonal);

      dynamic query = supabaseClient
          .from(historyTable)
          .select()
          .eq('transaction_id', transactionId);

      if (filterEventType != null &&
          filterEventType.isNotEmpty &&
          filterEventType != 'All') {
        final formattedEvent = filterEventType.toLowerCase().replaceAll(
          ' ',
          '_',
        );
        query = query.eq('event_type', formattedEvent);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.ilike('notes', '%${searchQuery.trim()}%');
      }

      final response = await query
          .order('created_at', ascending: ascending)
          .range(offset, offset + limit - 1);
      final list = (response as List)
          .map((item) => MoneyTransactionHistoryModel.fromJson(item))
          .toList();

      // Legacy fallback: If no history items found on initial page fetch, auto-create debt_created history item
      if (list.isEmpty &&
          offset == 0 &&
          (filterEventType == null || filterEventType == 'All') &&
          (searchQuery == null || searchQuery.isEmpty)) {
        final parentTable = _getParentTable(isPersonal);
        final parentRes = await supabaseClient
            .from(parentTable)
            .select()
            .eq('id', transactionId)
            .maybeSingle();
        if (parentRes != null) {
          final parent = MoneyTransactionModel.fromJson(parentRes);
          final historyCreatedData = <String, dynamic>{
            'transaction_id': parent.id,
            'event_type': 'debt_created',
            'amount': parent.amount,
            'balance_after': parent.balanceAmount,
            'notes': parent.notes.isNotEmpty ? parent.notes : 'Debt Created',
            'created_at': parent.createdAt.toUtc().toIso8601String(),
          };
          if (isPersonal && parent.userId != null)
            historyCreatedData['user_id'] = parent.userId;
          if (!isPersonal && parent.businessId != null)
            historyCreatedData['business_id'] = parent.businessId;

          final insertedHistory = await supabaseClient
              .from(historyTable)
              .insert(historyCreatedData)
              .select()
              .single();
          list.add(MoneyTransactionHistoryModel.fromJson(insertedHistory));

          if (parent.paidAmount > 0) {
            final paymentHistoryData = <String, dynamic>{
              'transaction_id': parent.id,
              'event_type': 'payment',
              'amount': parent.paidAmount,
              'balance_after': parent.balanceAmount,
              'payment_method': 'Cash',
              'notes': 'Initial Payment',
              'created_at': parent.createdAt
                  .add(const Duration(seconds: 1))
                  .toUtc()
                  .toIso8601String(),
            };
            if (isPersonal && parent.userId != null)
              paymentHistoryData['user_id'] = parent.userId;
            if (!isPersonal && parent.businessId != null)
              paymentHistoryData['business_id'] = parent.businessId;

            final insertedPayment = await supabaseClient
                .from(historyTable)
                .insert(paymentHistoryData)
                .select()
                .single();
            list.add(MoneyTransactionHistoryModel.fromJson(insertedPayment));
          }
        }
      }

      return list;
    } catch (e) {
      throw ServerException('Failed to get transaction history: $e');
    }
  }

  @override
  Future<MoneyTransactionHistoryModel> addPaymentHistory({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) async {
    try {
      final historyTable = _getHistoryTable(isPersonal);
      final parentTable = _getParentTable(isPersonal);

      // Fetch parent transaction to calculate new balance_after
      final parentRes = await supabaseClient
          .from(parentTable)
          .select()
          .eq('id', transactionId)
          .single();
      final parent = MoneyTransactionModel.fromJson(parentRes);

      final double newPaidAmount = parent.paidAmount + amount;
      double newBalance = parent.amount - newPaidAmount;
      if (newBalance < 0) newBalance = 0.0;

      final historyData = <String, dynamic>{
        'transaction_id': transactionId,
        'event_type': 'payment',
        'amount': amount,
        'balance_after': newBalance,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (createdBy != null && createdBy.isNotEmpty) {
        historyData['created_by'] = createdBy;
      }
      if (isPersonal && parent.userId != null) {
        historyData['user_id'] = parent.userId;
      }
      if (!isPersonal && parent.businessId != null) {
        historyData['business_id'] = parent.businessId;
      }

      final response = await supabaseClient
          .from(historyTable)
          .insert(historyData)
          .select()
          .single();
      final model = MoneyTransactionHistoryModel.fromJson(response);

      await _recalculateParentTotals(
        transactionId: transactionId,
        isPersonal: isPersonal,
      );

      return model;
    } catch (e) {
      throw ServerException('Failed to add payment history: $e');
    }
  }

  @override
  Future<MoneyTransactionHistoryModel> addAdjustmentHistory({
    required String transactionId,
    required double amount,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) async {
    try {
      final historyTable = _getHistoryTable(isPersonal);
      final parentTable = _getParentTable(isPersonal);

      final parentRes = await supabaseClient
          .from(parentTable)
          .select()
          .eq('id', transactionId)
          .single();
      final parent = MoneyTransactionModel.fromJson(parentRes);

      final double newTotalAmount = parent.amount + amount;
      double newBalance = newTotalAmount - parent.paidAmount;
      if (newBalance < 0) newBalance = 0.0;

      final historyData = <String, dynamic>{
        'transaction_id': transactionId,
        'event_type': 'adjustment',
        'amount': amount,
        'balance_after': newBalance,
        'notes': notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (createdBy != null && createdBy.isNotEmpty) {
        historyData['created_by'] = createdBy;
      }
      if (isPersonal && parent.userId != null) {
        historyData['user_id'] = parent.userId;
      }
      if (!isPersonal && parent.businessId != null) {
        historyData['business_id'] = parent.businessId;
      }

      final response = await supabaseClient
          .from(historyTable)
          .insert(historyData)
          .select()
          .single();
      final model = MoneyTransactionHistoryModel.fromJson(response);

      await _recalculateParentTotals(
        transactionId: transactionId,
        isPersonal: isPersonal,
      );

      return model;
    } catch (e) {
      throw ServerException('Failed to add adjustment history: $e');
    }
  }

  @override
  Future<MoneyTransactionHistoryModel> addReminderHistory({
    required String transactionId,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) async {
    try {
      final historyTable = _getHistoryTable(isPersonal);
      final parentTable = _getParentTable(isPersonal);

      final parentRes = await supabaseClient
          .from(parentTable)
          .select()
          .eq('id', transactionId)
          .single();
      final parent = MoneyTransactionModel.fromJson(parentRes);

      final historyData = <String, dynamic>{
        'transaction_id': transactionId,
        'event_type': 'reminder_sent',
        'amount': 0.0,
        'balance_after': parent.balanceAmount,
        'notes': notes,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (createdBy != null && createdBy.isNotEmpty) {
        historyData['created_by'] = createdBy;
      }
      if (isPersonal && parent.userId != null) {
        historyData['user_id'] = parent.userId;
      }
      if (!isPersonal && parent.businessId != null) {
        historyData['business_id'] = parent.businessId;
      }

      final response = await supabaseClient
          .from(historyTable)
          .insert(historyData)
          .select()
          .single();
      return MoneyTransactionHistoryModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to add reminder history: $e');
    }
  }

  @override
  Future<MoneyTransactionHistoryModel> updateHistoryItem({
    required MoneyTransactionHistoryModel historyItem,
    required bool isPersonal,
  }) async {
    try {
      final historyTable = _getHistoryTable(isPersonal);

      final updateData = <String, dynamic>{
        'amount': historyItem.amount,
        'notes': historyItem.notes,
        'event_type': MoneyTransactionHistoryModel.sanitizeEventType(
          historyItem.eventType,
        ),
      };
      if (historyItem.paymentMethod != null &&
          historyItem.paymentMethod!.isNotEmpty) {
        updateData['payment_method'] = historyItem.paymentMethod;
      }

      final response = await supabaseClient
          .from(historyTable)
          .update(updateData)
          .eq('id', historyItem.id)
          .select()
          .single();

      final updatedModel = MoneyTransactionHistoryModel.fromJson(response);

      await _recalculateParentTotals(
        transactionId: historyItem.transactionId,
        isPersonal: isPersonal,
      );

      return updatedModel;
    } catch (e) {
      throw ServerException('Failed to update history item: $e');
    }
  }

  @override
  Future<void> deleteHistoryItem({
    required String historyId,
    required String transactionId,
    required bool isPersonal,
  }) async {
    try {
      final historyTable = _getHistoryTable(isPersonal);

      await supabaseClient.from(historyTable).delete().eq('id', historyId);

      await _recalculateParentTotals(
        transactionId: transactionId,
        isPersonal: isPersonal,
      );
    } catch (e) {
      throw ServerException('Failed to delete history item: $e');
    }
  }

  /// Recalculates parent transaction totals based on history records
  Future<void> _recalculateParentTotals({
    required String transactionId,
    required bool isPersonal,
  }) async {
    final parentTable = _getParentTable(isPersonal);
    final historyTable = _getHistoryTable(isPersonal);

    // Fetch parent transaction
    final parentRes = await supabaseClient
        .from(parentTable)
        .select()
        .eq('id', transactionId)
        .maybeSingle();
    if (parentRes == null) return;
    final parentModel = MoneyTransactionModel.fromJson(parentRes);

    // Fetch all history records for transaction
    final historyRes = await supabaseClient
        .from(historyTable)
        .select()
        .eq('transaction_id', transactionId);
    final historyItems = (historyRes as List)
        .map((i) => MoneyTransactionHistoryModel.fromJson(i))
        .toList();

    double totalPaid = 0.0;
    double netAdjustment = 0.0;
    double initialDebt = 0.0;
    double addedDebt = 0.0;

    for (final item in historyItems) {
      if (item.eventType == 'payment' || item.eventType == 'payment_updated') {
        totalPaid += item.amount;
      } else if (item.eventType == 'adjustment') {
        netAdjustment += item.amount;
      } else if (item.eventType == 'debt_created') {
        initialDebt += item.amount;
      } else if (item.eventType == 'debt_added') {
        addedDebt += item.amount;
      }
    }

    // Floating point precision rounding (2 decimal places)
    totalPaid = (totalPaid * 100).roundToDouble() / 100.0;

    double updatedTotalAmount;
    if (initialDebt > 0 || addedDebt > 0) {
      updatedTotalAmount = ((initialDebt + addedDebt + netAdjustment) * 100).roundToDouble() / 100.0;
    } else {
      updatedTotalAmount = ((parentModel.amount + netAdjustment) * 100).roundToDouble() / 100.0;
    }

    double balance = updatedTotalAmount - totalPaid;
    balance = (balance * 100).roundToDouble() / 100.0;

    if (balance < 0) balance = 0.0;

    final String updatedStatus = balance <= 0 ? 'Completed' : 'Pending';

    final mapData = {
      'amount': updatedTotalAmount,
      'paid_amount': totalPaid,
      'balance_amount': balance,
      'status': updatedStatus,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await supabaseClient
        .from(parentTable)
        .update(mapData)
        .eq('id', transactionId);
  }
}
