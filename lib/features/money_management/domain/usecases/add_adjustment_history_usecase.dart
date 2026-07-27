import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class AddAdjustmentHistoryUseCase {
  final MoneyManagementRepository repository;

  AddAdjustmentHistoryUseCase(this.repository);

  Future<MoneyTransactionHistoryEntity> execute({
    required String transactionId,
    required double amount,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) {
    return repository.addAdjustmentHistory(
      transactionId: transactionId,
      amount: amount,
      notes: notes,
      isPersonal: isPersonal,
      createdBy: createdBy,
    );
  }
}
