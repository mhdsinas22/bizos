import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class UpdateHistoryItemUseCase {
  final MoneyManagementRepository repository;

  UpdateHistoryItemUseCase(this.repository);

  Future<MoneyTransactionHistoryEntity> execute({
    required MoneyTransactionHistoryEntity historyItem,
    required bool isPersonal,
  }) {
    return repository.updateHistoryItem(
      historyItem: historyItem,
      isPersonal: isPersonal,
    );
  }
}
