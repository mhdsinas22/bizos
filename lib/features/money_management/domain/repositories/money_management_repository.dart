import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';

abstract class MoneyManagementRepository {
  Stream<List<MoneyTransactionEntity>> watchPersonalTransactions(String userId);
  Stream<List<MoneyTransactionEntity>> watchBusinessTransactions(String businessId);
  Future<MoneyTransactionEntity> addTransaction(MoneyTransactionEntity transaction, bool isPersonal);
  Future<void> updateTransaction(MoneyTransactionEntity transaction, bool isPersonal);
  Future<MoneyTransactionEntity?> deleteTransaction(String id, bool isPersonal);
}
