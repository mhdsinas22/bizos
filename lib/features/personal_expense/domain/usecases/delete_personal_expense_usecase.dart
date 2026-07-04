import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class DeletePersonalExpenseUseCase {
  final PersonalExpenseRepository repository;

  DeletePersonalExpenseUseCase({required this.repository});

  Future<void> execute(String expenseId, String userId) async {
    return repository.deleteExpense(expenseId, userId);
  }
}
