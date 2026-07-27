import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class DeleteHistoryItemUseCase {
  final MoneyManagementRepository repository;

  DeleteHistoryItemUseCase(this.repository);

  Future<void> execute({
    required String historyId,
    required String transactionId,
    required bool isPersonal,
  }) {
    return repository.deleteHistoryItem(
      historyId: historyId,
      transactionId: transactionId,
      isPersonal: isPersonal,
    );
  }
}
