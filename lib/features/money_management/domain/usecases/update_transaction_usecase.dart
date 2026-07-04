import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class UpdateTransactionUseCase {
  final MoneyManagementRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<void> execute(MoneyTransactionEntity transaction, bool isPersonal) async {
    await repository.updateTransaction(transaction, isPersonal);
  }
}
