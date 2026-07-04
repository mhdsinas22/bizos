import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class GetPersonalExpensesUseCase {
  final PersonalExpenseRepository repository;

  GetPersonalExpensesUseCase({required this.repository});

  Future<List<PersonalExpenseEntity>> execute(String userId) async {
    return repository.getExpenses(userId);
  }
}
