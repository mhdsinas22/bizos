import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class GetTransactionByIdUseCase {
  final MoneyManagementRepository repository;

  GetTransactionByIdUseCase(this.repository);

  Future<MoneyTransactionEntity?> execute({
    required String id,
    required bool isPersonal,
  }) async {
    return await repository.getTransactionById(id: id, isPersonal: isPersonal);
  }
}
