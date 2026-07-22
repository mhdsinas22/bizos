import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class DeleteTransactionUseCase {
  final MoneyManagementRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<MoneyTransactionEntity?> execute(String id, bool isPersonal) async {
    return await repository.deleteTransaction(id, isPersonal);
  }
}
