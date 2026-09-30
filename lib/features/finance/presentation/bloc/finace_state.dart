import 'package:equatable/equatable.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<IncomeModel> incomeList;
  final List<ExpenseModel> expenseList;

  const FinanceLoaded(this.incomeList, this.expenseList);

  @override
  List<Object?> get props => [incomeList, expenseList];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
