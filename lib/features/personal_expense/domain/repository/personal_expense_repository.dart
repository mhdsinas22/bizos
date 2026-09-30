import 'package:bizos/features/personal_expense/domain/entities/personal_expense_category_entity.dart';
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

  // Category Methods
  Future<List<PersonalExpenseCategoryEntity>> getCategories(String userId);
  Future<PersonalExpenseCategoryEntity> addCategory(
      PersonalExpenseCategoryEntity category, String userId);
  Future<void> updateCategory(
      PersonalExpenseCategoryEntity category, String userId);
  Future<void> deleteCategory(String categoryId, String userId);
  Future<bool> isCategoryUsed(String categoryName, String userId);
}
