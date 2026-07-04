import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class DeleteTransactionUseCase {
  final MoneyManagementRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<void> execute(String id, bool isPersonal) async {
    await repository.deleteTransaction(id, isPersonal);
  }
}
