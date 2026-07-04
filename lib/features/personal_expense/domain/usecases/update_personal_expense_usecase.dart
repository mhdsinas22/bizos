import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class UpdatePersonalExpenseUseCase {
  final PersonalExpenseRepository repository;

  UpdatePersonalExpenseUseCase({required this.repository});

  Future<void> execute(PersonalExpenseEntity expense, String userId) async {
    return repository.updateExpense(expense, userId);
  }
}
