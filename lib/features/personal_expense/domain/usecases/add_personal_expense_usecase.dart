import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class AddPersonalExpenseUseCase {
  final PersonalExpenseRepository repository;

  AddPersonalExpenseUseCase({required this.repository});

  Future<void> execute(PersonalExpenseEntity expense, String userId) async {
    return repository.addExpense(expense, userId);
  }
}
