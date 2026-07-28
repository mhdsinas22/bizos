import 'package:bizos/features/money_management/domain/entities/debt_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class AddDebtUseCase {
  final MoneyManagementRepository repository;

  AddDebtUseCase(this.repository);

  Future<MoneyTransactionEntity> execute({
    required DebtEntity debt,
    required bool isPersonal,
  }) async {
    return await repository.addDebt(debt: debt, isPersonal: isPersonal);
  }
}
