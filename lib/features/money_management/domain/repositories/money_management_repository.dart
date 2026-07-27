import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';

abstract class MoneyManagementRepository {
  Stream<List<MoneyTransactionEntity>> watchPersonalTransactions(String userId);
  Stream<List<MoneyTransactionEntity>> watchBusinessTransactions(String businessId);
  Future<MoneyTransactionEntity> addTransaction(MoneyTransactionEntity transaction, bool isPersonal);
  Future<void> updateTransaction(MoneyTransactionEntity transaction, bool isPersonal);
  Future<MoneyTransactionEntity?> deleteTransaction(String id, bool isPersonal);

  // History Methods
  Future<List<MoneyTransactionHistoryEntity>> getTransactionHistory({
    required String transactionId,
    required bool isPersonal,
    required int limit,
    required int offset,
    String? filterEventType,
    String? searchQuery,
    bool ascending = false,
  });

  Future<MoneyTransactionHistoryEntity> addPaymentHistory({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  });

  Future<MoneyTransactionHistoryEntity> addAdjustmentHistory({
    required String transactionId,
    required double amount,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  });

  Future<MoneyTransactionHistoryEntity> addReminderHistory({
    required String transactionId,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  });

  Future<MoneyTransactionHistoryEntity> updateHistoryItem({
    required MoneyTransactionHistoryEntity historyItem,
    required bool isPersonal,
  });

  Future<void> deleteHistoryItem({
    required String historyId,
    required String transactionId,
    required bool isPersonal,
  });
}

