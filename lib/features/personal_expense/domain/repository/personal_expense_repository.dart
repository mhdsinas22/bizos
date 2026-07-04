import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';

abstract class PersonalExpenseRepository {
  Future<List<PersonalExpenseEntity>> getExpenses(String userId);
  Future<void> addExpense(PersonalExpenseEntity expense, String userId);
  Future<void> updateExpense(PersonalExpenseEntity expense, String userId);
  Future<void> deleteExpense(String expenseId, String userId);
  Future<List<PersonalExpenseEntity>> getFilteredExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Map<String, double>> getCategoryAnalytics(String userId);
}
