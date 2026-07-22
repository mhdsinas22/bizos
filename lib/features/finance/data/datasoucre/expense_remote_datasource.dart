import 'package:bizos/features/finance/data/models/expense_model.dart';

abstract class ExpenseRemoteDatasource {
  Future<List<ExpenseModel>> getExpenseList(String businessId);
  Future<List<ExpenseModel>> getAllExpenses();
  Future<void> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<ExpenseModel?> deleteExpense(String id);
}
