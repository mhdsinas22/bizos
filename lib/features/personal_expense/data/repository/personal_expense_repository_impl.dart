import 'package:bizos/features/personal_expense/data/datasource/personal_expense_remote_datasource.dart';
import 'package:bizos/features/personal_expense/data/models/personal_expense_model.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class PersonalExpenseRepositoryImpl implements PersonalExpenseRepository {
  final PersonalExpenseRemoteDatasource remoteDataSource;

  PersonalExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PersonalExpenseEntity>> getExpenses(String userId) async {
    final models = await remoteDataSource.getExpenses(userId);
    return models.cast<PersonalExpenseEntity>();
  }

  @override
  Future<void> addExpense(PersonalExpenseEntity expense, String userId) async {
    final model = PersonalExpenseModel.fromEntity(expense);
    return remoteDataSource.addExpense(model, userId);
  }

  @override
  Future<void> updateExpense(PersonalExpenseEntity expense, String userId) async {
    final model = PersonalExpenseModel.fromEntity(expense);
    return remoteDataSource.updateExpense(model, userId);
  }

  @override
  Future<void> deleteExpense(String expenseId, String userId) async {
    return remoteDataSource.deleteExpense(expenseId, userId);
  }

  @override
  Future<List<PersonalExpenseEntity>> getFilteredExpenses(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final models = await remoteDataSource.getFilteredExpenses(
      userId,
      startDate: startDate,
      endDate: endDate,
    );
    return models.cast<PersonalExpenseEntity>();
  }

  @override
  Future<Map<String, double>> getCategoryAnalytics(String userId) async {
    final expenses = await getExpenses(userId);
    final Map<String, double> analytics = {};
    for (final expense in expenses) {
      analytics[expense.category] = (analytics[expense.category] ?? 0.0) + expense.amount;
    }
    return analytics;
  }
}
