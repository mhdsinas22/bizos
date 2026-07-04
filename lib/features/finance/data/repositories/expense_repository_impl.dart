import 'package:bizos/features/finance/data/datasoucre/expense_remote_datasource.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource expenseRemoteDatasource;
  final DashboardRemoteDatasource dashboardRemoteDatasource;

  ExpenseRepositoryImpl({
    required this.expenseRemoteDatasource,
    required this.dashboardRemoteDatasource,
  });

  @override
  Future<List<ExpenseModel>> getExpenseList(String businessId) async {
    try {
      return await expenseRemoteDatasource.getExpenseList(businessId);
    } catch (e) {
      print("Error fetching expense list: $e");
      rethrow;
    }
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      return await expenseRemoteDatasource.getAllExpenses();
    } catch (e) {
      print("Error fetching all expenses: $e");
      rethrow;
    }
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await expenseRemoteDatasource.addExpense(expense);
      // Automatically log activity
      await dashboardRemoteDatasource.logActivity(
        businessId: expense.businessId,
        title: "Add Expense",
        description:
            "Logged Expense: ${expense.category} - ${expense.description}",
        amount: expense.amount,
      );
    } catch (e) {
      print("Error adding expense: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await expenseRemoteDatasource.updateExpense(expense);
    } catch (e) {
      print("Error updating expense: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await expenseRemoteDatasource.deleteExpense(id);
    } catch (e) {
      print("Error deleting expense: $e");
      rethrow;
    }
  }
}
