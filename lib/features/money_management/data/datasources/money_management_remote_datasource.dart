import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MoneyManagementRemoteDatasource {
  Stream<List<MoneyTransactionModel>> watchPersonalTransactions(String userId);
  Stream<List<MoneyTransactionModel>> watchBusinessTransactions(String businessId);
  Future<MoneyTransactionModel> addTransaction(MoneyTransactionModel transaction, bool isPersonal);
  Future<void> updateTransaction(MoneyTransactionModel transaction, bool isPersonal);
  Future<MoneyTransactionModel?> deleteTransaction(String id, bool isPersonal);
}

class MoneyManagementRemoteDatasourceImpl implements MoneyManagementRemoteDatasource {
  final SupabaseClient supabaseClient;

  MoneyManagementRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Stream<List<MoneyTransactionModel>> watchPersonalTransactions(String userId) {
    try {
      return supabaseClient
          .from('personal_money_transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map((list) {
            final models = list.map((item) => MoneyTransactionModel.fromJson(item)).toList();
            models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return models;
          });
    } catch (e) {
      throw ServerException('Failed to watch personal transactions: $e');
    }
  }

  @override
  Stream<List<MoneyTransactionModel>> watchBusinessTransactions(String businessId) {
    try {
      return supabaseClient
          .from('business_money_transactions')
          .stream(primaryKey: ['id'])
          .eq('business_id', businessId)
          .map((list) {
            final models = list.map((item) => MoneyTransactionModel.fromJson(item)).toList();
            models.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return models;
          });
    } catch (e) {
      throw ServerException('Failed to watch business transactions: $e');
    }
  }

  @override
  Future<MoneyTransactionModel> addTransaction(MoneyTransactionModel transaction, bool isPersonal) async {
    try {
      final table = isPersonal ? 'personal_money_transactions' : 'business_money_transactions';
      final mapData = transaction.toJson();
      if (transaction.id.isEmpty) {
        mapData.remove('id');
      }
      final response = await supabaseClient.from(table).insert(mapData).select().single();
      return MoneyTransactionModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to add transaction: $e');
    }
  }

  @override
  Future<void> updateTransaction(MoneyTransactionModel transaction, bool isPersonal) async {
    try {
      final table = isPersonal ? 'personal_money_transactions' : 'business_money_transactions';
      final mapData = {
        'person_name': transaction.personName,
        'phone': transaction.phone,
        'amount': transaction.amount,
        'paid_amount': transaction.paidAmount,
        'balance_amount': transaction.balanceAmount,
        'due_date': transaction.dueDate?.toIso8601String(),
        'notes': transaction.notes,
        'status': transaction.status,
      };
      await supabaseClient
          .from(table)
          .update(mapData)
          .eq('id', transaction.id);
    } catch (e) {
      throw ServerException('Failed to update transaction: $e');
    }
  }

  @override
  Future<MoneyTransactionModel?> deleteTransaction(String id, bool isPersonal) async {
    try {
      final table = isPersonal ? 'personal_money_transactions' : 'business_money_transactions';
      final response = await supabaseClient.from(table).select().eq('id', id).maybeSingle();
      if (response != null) {
        final model = MoneyTransactionModel.fromJson(response);
        await supabaseClient.from(table).delete().eq('id', id);
        return model;
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to delete transaction: $e');
    }
  }
}
