import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/money_management/data/datasources/money_management_remote_datasource.dart';
import 'package:bizos/features/money_management/data/models/debt_model.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_model.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_history_model.dart';
import 'package:bizos/features/money_management/domain/entities/debt_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class MoneyManagementRepositoryImpl implements MoneyManagementRepository {
  final MoneyManagementRemoteDatasource remoteDatasource;
  final ActivityRepository activityRepository;

  MoneyManagementRepositoryImpl({
    required this.remoteDatasource,
    required this.activityRepository,
  });

  @override
  Stream<List<MoneyTransactionEntity>> watchPersonalTransactions(
    String userId,
  ) {
    return remoteDatasource.watchPersonalTransactions(userId);
  }

  @override
  Stream<List<MoneyTransactionEntity>> watchBusinessTransactions(
    String businessId,
  ) {
    return remoteDatasource.watchBusinessTransactions(businessId);
  }

  @override
  Future<MoneyTransactionEntity> addTransaction(
    MoneyTransactionEntity transaction,
    bool isPersonal,
  ) async {
    final model = MoneyTransactionModel.fromEntity(transaction);
    final createdModel = await remoteDatasource.addTransaction(
      model,
      isPersonal,
    );

    final title = transaction.transactionType == 'pay'
        ? 'Money To Pay Added'
        : 'Money To Receive Added';
    await activityRepository.logActivity(
      businessId: isPersonal ? null : transaction.businessId,
      title: title,
      description:
          "Person: ${transaction.personName} | Amount: ${transaction.amount} | Phone: ${transaction.phone}",
      module: "Money",
      action: "Add",
      referenceId: createdModel.id,
    );
    return createdModel;
  }

  @override
  Future<MoneyTransactionEntity> addDebt({
    required DebtEntity debt,
    required bool isPersonal,
  }) async {
    final model = DebtModel.fromEntity(debt);
    final createdModel = await remoteDatasource.addDebt(model, isPersonal);

    await activityRepository.logActivity(
      businessId: isPersonal ? null : debt.businessId,
      title: "Debt Added",
      description:
          "Person: ${debt.personName} | Amount: ${debt.amount} | Notes: ${debt.notes}",
      module: "Money",
      action: "AddDebt",
      referenceId: createdModel.id,
    );

    return createdModel;
  }

  @override
  Future<MoneyTransactionEntity> createDebt({
    required DebtEntity debt,
    required bool isPersonal,
  }) async {
    return addDebt(debt: debt, isPersonal: isPersonal);
  }

  @override
  Future<MoneyTransactionEntity?> getTransactionById({
    required String id,
    required bool isPersonal,
  }) async {
    return await remoteDatasource.getTransactionById(id, isPersonal);
  }

  @override
  Future<void> updateTransaction(
    MoneyTransactionEntity transaction,
    bool isPersonal,
  ) async {
    final model = MoneyTransactionModel.fromEntity(transaction);
    await remoteDatasource.updateTransaction(model, isPersonal);

    await activityRepository.logActivity(
      businessId: isPersonal ? null : transaction.businessId,
      title: "Money Updated",
      description:
          "Person: ${transaction.personName} | Amount: ${transaction.amount} | Balance: ${transaction.balanceAmount}",
      module: "Money",
      action: "Update",
      referenceId: transaction.id,
    );
  }

  @override
  Future<MoneyTransactionEntity?> deleteTransaction(
    String id,
    bool isPersonal,
  ) async {
    final deleted = await remoteDatasource.deleteTransaction(id, isPersonal);
    if (deleted != null) {
      await activityRepository.logActivity(
        businessId: isPersonal ? null : deleted.businessId,
        title: "Money Deleted",
        description:
            "Person: ${deleted.personName} | Amount: ${deleted.amount}",
        module: "Money",
        action: "Delete",
        referenceId: id,
      );
    }
    return deleted;
  }

  @override
  Future<List<MoneyTransactionHistoryEntity>> getTransactionHistory({
    required String transactionId,
    required bool isPersonal,
    required int limit,
    required int offset,
    String? filterEventType,
    String? searchQuery,
    bool ascending = false,
  }) {
    return remoteDatasource.getTransactionHistory(
      transactionId: transactionId,
      isPersonal: isPersonal,
      limit: limit,
      offset: offset,
      filterEventType: filterEventType,
      searchQuery: searchQuery,
      ascending: ascending,
    );
  }

  @override
  Future<MoneyTransactionHistoryEntity> addPaymentHistory({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) async {
    final created = await remoteDatasource.addPaymentHistory(
      transactionId: transactionId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      isPersonal: isPersonal,
      createdBy: createdBy,
    );

    await activityRepository.logActivity(
      businessId: isPersonal ? null : null,
      title: "Payment Recorded",
      description: "Payment: ₹$amount ($paymentMethod) | Notes: $notes",
      module: "Money",
      action: "Payment",
      referenceId: transactionId,
    );

    return created;
  }

  @override
  Future<MoneyTransactionHistoryEntity> addAdjustmentHistory({
    required String transactionId,
    required double amount,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) async {
    final created = await remoteDatasource.addAdjustmentHistory(
      transactionId: transactionId,
      amount: amount,
      notes: notes,
      isPersonal: isPersonal,
      createdBy: createdBy,
    );

    await activityRepository.logActivity(
      businessId: isPersonal ? null : null,
      title: "Adjustment Recorded",
      description: "Adjustment: ₹$amount | Notes: $notes",
      module: "Money",
      action: "Adjustment",
      referenceId: transactionId,
    );

    return created;
  }

  @override
  Future<MoneyTransactionHistoryEntity> addReminderHistory({
    required String transactionId,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) async {
    final created = await remoteDatasource.addReminderHistory(
      transactionId: transactionId,
      notes: notes,
      isPersonal: isPersonal,
      createdBy: createdBy,
    );

    await activityRepository.logActivity(
      businessId: isPersonal ? null : null,
      title: "Payment Reminder Sent",
      description: "Reminder: $notes",
      module: "Money",
      action: "Reminder",
      referenceId: transactionId,
    );

    return created;
  }

  @override
  Future<MoneyTransactionHistoryEntity> updateHistoryItem({
    required MoneyTransactionHistoryEntity historyItem,
    required bool isPersonal,
  }) async {
    final model = MoneyTransactionHistoryModel.fromEntity(historyItem);
    final updated = await remoteDatasource.updateHistoryItem(
      historyItem: model,
      isPersonal: isPersonal,
    );

    await activityRepository.logActivity(
      businessId: isPersonal ? null : null,
      title: "History Event Updated",
      description:
          "Event: ${historyItem.eventType} | Amount: ₹${historyItem.amount}",
      module: "Money",
      action: "UpdateHistory",
      referenceId: historyItem.transactionId,
    );

    return updated;
  }

  @override
  Future<void> deleteHistoryItem({
    required String historyId,
    required String transactionId,
    required bool isPersonal,
  }) async {
    await remoteDatasource.deleteHistoryItem(
      historyId: historyId,
      transactionId: transactionId,
      isPersonal: isPersonal,
    );

    await activityRepository.logActivity(
      businessId: isPersonal ? null : null,
      title: "History Event Deleted",
      description: "Deleted History ID: $historyId",
      module: "Money",
      action: "DeleteHistory",
      referenceId: transactionId,
    );
  }
}
