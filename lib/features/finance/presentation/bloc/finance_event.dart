import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';

abstract class FinanceEvent {}

class FetchFinanceDataEvent extends FinanceEvent {
  final String businessId;
  FetchFinanceDataEvent(this.businessId);
}

class AddIncomeEvent extends FinanceEvent {
  final IncomeModel income;
  AddIncomeEvent(this.income);
}

class UpdateIncomeEvent extends FinanceEvent {
  final IncomeModel income;
  UpdateIncomeEvent(this.income);
}

class DeleteIncomeEvent extends FinanceEvent {
  final String id;
  final String businessId;
  DeleteIncomeEvent(this.id, this.businessId);
}

class AddExpenseEvent extends FinanceEvent {
  final ExpenseModel expense;
  AddExpenseEvent(this.expense);
}

class UpdateExpenseEvent extends FinanceEvent {
  final ExpenseModel expense;
  UpdateExpenseEvent(this.expense);
}

class DeleteExpenseEvent extends FinanceEvent {
  final String id;
  final String businessId;
  DeleteExpenseEvent(this.id, this.businessId);
}
