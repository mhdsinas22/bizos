import 'package:bizos/features/money_management/data/datasources/money_management_remote_datasource.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_model.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class MoneyManagementRepositoryImpl implements MoneyManagementRepository {
  final MoneyManagementRemoteDatasource remoteDatasource;

  MoneyManagementRepositoryImpl({required this.remoteDatasource});

  @override
  Stream<List<MoneyTransactionEntity>> watchPersonalTransactions(String userId) {
    return remoteDatasource.watchPersonalTransactions(userId);
  }

  @override
  Stream<List<MoneyTransactionEntity>> watchBusinessTransactions(String businessId) {
    return remoteDatasource.watchBusinessTransactions(businessId);
  }

  @override
  Future<void> addTransaction(MoneyTransactionEntity transaction, bool isPersonal) async {
    final model = MoneyTransactionModel.fromEntity(transaction);
    await remoteDatasource.addTransaction(model, isPersonal);
  }

  @override
  Future<void> updateTransaction(MoneyTransactionEntity transaction, bool isPersonal) async {
    final model = MoneyTransactionModel.fromEntity(transaction);
    await remoteDatasource.updateTransaction(model, isPersonal);
  }

  @override
  Future<void> deleteTransaction(String id, bool isPersonal) async {
    await remoteDatasource.deleteTransaction(id, isPersonal);
  }
}
