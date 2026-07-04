import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';

abstract class FinanceState {}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<IncomeModel> incomeList;
  final List<ExpenseModel> expenseList;
  FinanceLoaded(this.incomeList, this.expenseList);
}

class FinanceError extends FinanceState {
  final String message;
  FinanceError(this.message);
}
