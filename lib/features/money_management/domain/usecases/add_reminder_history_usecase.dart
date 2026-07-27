import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class AddReminderHistoryUseCase {
  final MoneyManagementRepository repository;

  AddReminderHistoryUseCase(this.repository);

  Future<MoneyTransactionHistoryEntity> execute({
    required String transactionId,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) {
    return repository.addReminderHistory(
      transactionId: transactionId,
      notes: notes,
      isPersonal: isPersonal,
      createdBy: createdBy,
    );
  }
}
