import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class GetFilteredExpensesUseCase {
  final PersonalExpenseRepository repository;

  GetFilteredExpensesUseCase({required this.repository});

  Future<List<PersonalExpenseEntity>> execute(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return repository.getFilteredExpenses(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
