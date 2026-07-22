import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/money_management/data/datasources/money_management_remote_datasource.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_model.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class MoneyManagementRepositoryImpl implements MoneyManagementRepository {
  final MoneyManagementRemoteDatasource remoteDatasource;
  final ActivityRepository activityRepository;

  MoneyManagementRepositoryImpl({
    required this.remoteDatasource,
    required this.activityRepository,
  });

  @override
  Stream<List<MoneyTransactionEntity>> watchPersonalTransactions(String userId) {
    return remoteDatasource.watchPersonalTransactions(userId);
  }

  @override
  Stream<List<MoneyTransactionEntity>> watchBusinessTransactions(String businessId) {
    return remoteDatasource.watchBusinessTransactions(businessId);
  }

  @override
  Future<MoneyTransactionEntity> addTransaction(MoneyTransactionEntity transaction, bool isPersonal) async {
    final model = MoneyTransactionModel.fromEntity(transaction);
    final createdModel = await remoteDatasource.addTransaction(model, isPersonal);

    final title = transaction.transactionType == 'pay' ? 'Money To Pay Added' : 'Money To Receive Added';
    await activityRepository.logActivity(
      businessId: isPersonal ? null : transaction.businessId,
      title: title,
      description: "Person: ${transaction.personName} | Amount: ${transaction.amount} | Phone: ${transaction.phone}",
      module: "Money",
      action: "Add",
      referenceId: createdModel.id,
    );
    return createdModel;
  }

  @override
  Future<void> updateTransaction(MoneyTransactionEntity transaction, bool isPersonal) async {
    final model = MoneyTransactionModel.fromEntity(transaction);
    await remoteDatasource.updateTransaction(model, isPersonal);

    await activityRepository.logActivity(
      businessId: isPersonal ? null : transaction.businessId,
      title: "Money Updated",
      description: "Person: ${transaction.personName} | Amount: ${transaction.amount} | Balance: ${transaction.balanceAmount}",
      module: "Money",
      action: "Update",
      referenceId: transaction.id,
    );
  }

  @override
  Future<MoneyTransactionEntity?> deleteTransaction(String id, bool isPersonal) async {
    final deleted = await remoteDatasource.deleteTransaction(id, isPersonal);
    if (deleted != null) {
      await activityRepository.logActivity(
        businessId: isPersonal ? null : deleted.businessId,
        title: "Money Deleted",
        description: "Person: ${deleted.personName} | Amount: ${deleted.amount}",
        module: "Money",
        action: "Delete",
        referenceId: id,
      );
    }
    return deleted;
  }
}
