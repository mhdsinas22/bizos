import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class WatchTransactionsUseCase {
  final MoneyManagementRepository repository;

  WatchTransactionsUseCase(this.repository);

  Stream<List<MoneyTransactionEntity>> execute({String? userId, String? businessId}) {
    if (businessId != null) {
      return repository.watchBusinessTransactions(businessId);
    } else if (userId != null) {
      return repository.watchPersonalTransactions(userId);
    } else {
      throw ArgumentError('Either userId or businessId must be provided to watch transactions.');
    }
  }
}
