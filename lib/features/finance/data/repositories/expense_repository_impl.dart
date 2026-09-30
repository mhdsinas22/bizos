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
  Future<List<ExpenseModel>> getExpenseList(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await expenseRemoteDatasource.getExpenseList(
      businessId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses() async {
    return await expenseRemoteDatasource.getAllExpenses();
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    await expenseRemoteDatasource.addExpense(expense);
    // Automatically log activity
    await activityRepository.logActivity(
      businessId: expense.businessId,
      title: "Expense Added",
      description:
          "Category: ${expense.category} | Method: ${expense.paymentMethod} | Amount: ${expense.amount} | Description: ${expense.description}",
      module: "Expense",
      action: "Add",
      referenceId: expense.id,
      createdBy: expense.createdByUserId,
    );
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await expenseRemoteDatasource.updateExpense(expense);
    // Automatically log activity
    await activityRepository.logActivity(
      businessId: expense.businessId,
      title: "Expense Updated",
      description:
          "Category: ${expense.category} | Method: ${expense.paymentMethod} | Amount: ${expense.amount} | Description: ${expense.description}",
      module: "Expense",
      action: "Update",
      referenceId: expense.id,
      createdBy: expense.createdByUserId,
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    final deleted = await expenseRemoteDatasource.deleteExpense(id);
    if (deleted != null) {
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: deleted.businessId,
        title: "Expense Deleted",
        description:
            "Category: ${deleted.category} | Method: ${deleted.paymentMethod} | Amount: ${deleted.amount} | Description: ${deleted.description}",
        module: "Expense",
        action: "Delete",
        referenceId: deleted.id,
        createdBy: deleted.createdByUserId,
      );
    }
  }
}
