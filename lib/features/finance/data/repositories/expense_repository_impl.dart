import 'package:bizos/features/finance/data/datasoucre/expense_remote_datasource.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDatasource expenseRemoteDatasource;
  final ActivityRepository activityRepository;

  ExpenseRepositoryImpl({
    required this.expenseRemoteDatasource,
    required this.activityRepository,
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
      await activityRepository.logActivity(
        businessId: expense.businessId,
        title: "Expense Added",
        description: "Category: ${expense.category} | Amount: ${expense.amount} | Description: ${expense.description}",
        module: "Expense",
        action: "Add",
        referenceId: expense.id,
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
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: expense.businessId,
        title: "Expense Updated",
        description: "Category: ${expense.category} | Amount: ${expense.amount} | Description: ${expense.description}",
        module: "Expense",
        action: "Update",
        referenceId: expense.id,
      );
    } catch (e) {
      print("Error updating expense: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final deleted = await expenseRemoteDatasource.deleteExpense(id);
      if (deleted != null) {
        // Automatically log activity
        await activityRepository.logActivity(
          businessId: deleted.businessId,
          title: "Expense Deleted",
          description: "Category: ${deleted.category} | Amount: ${deleted.amount} | Description: ${deleted.description}",
          module: "Expense",
          action: "Delete",
          referenceId: deleted.id,
        );
      }
    } catch (e) {
      print("Error deleting expense: $e");
      rethrow;
    }
  }
}
