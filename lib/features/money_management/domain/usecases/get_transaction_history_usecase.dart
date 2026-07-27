import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class GetTransactionHistoryUseCase {
  final MoneyManagementRepository repository;

  GetTransactionHistoryUseCase(this.repository);

  Future<List<MoneyTransactionHistoryEntity>> execute({
    required String transactionId,
    required bool isPersonal,
    required int limit,
    required int offset,
    String? filterEventType,
    String? searchQuery,
    bool ascending = false,
  }) {
    return repository.getTransactionHistory(
      transactionId: transactionId,
      isPersonal: isPersonal,
      limit: limit,
      offset: offset,
      filterEventType: filterEventType,
      searchQuery: searchQuery,
      ascending: ascending,
    );
  }
}
