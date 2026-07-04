import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';

abstract class MoneyManagementRepository {
  Stream<List<MoneyTransactionEntity>> watchPersonalTransactions(String userId);
  Stream<List<MoneyTransactionEntity>> watchBusinessTransactions(String businessId);
  Future<void> addTransaction(MoneyTransactionEntity transaction, bool isPersonal);
  Future<void> updateTransaction(MoneyTransactionEntity transaction, bool isPersonal);
  Future<void> deleteTransaction(String id, bool isPersonal);
}
