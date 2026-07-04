import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class AddTransactionUseCase {
  final MoneyManagementRepository repository;

  AddTransactionUseCase(this.repository);

  Future<void> execute(MoneyTransactionEntity transaction, bool isPersonal) async {
    await repository.addTransaction(transaction, isPersonal);
  }
}
