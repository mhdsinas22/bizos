import 'package:equatable/equatable.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class FetchFinanceDataEvent extends FinanceEvent {
  final String businessId;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchFinanceDataEvent(this.businessId, {this.startDate, this.endDate});

  @override
  List<Object?> get props => [businessId, startDate, endDate];
}

class AddIncomeEvent extends FinanceEvent {
  final IncomeModel income;

  const AddIncomeEvent(this.income);

  @override
  List<Object?> get props => [income];
}

class UpdateIncomeEvent extends FinanceEvent {
  final IncomeModel income;

  const UpdateIncomeEvent(this.income);

  @override
  List<Object?> get props => [income];
}

class DeleteIncomeEvent extends FinanceEvent {
  final String id;
  final String businessId;

  const DeleteIncomeEvent(this.id, this.businessId);

  @override
  List<Object?> get props => [id, businessId];
}

class AddExpenseEvent extends FinanceEvent {
  final ExpenseModel expense;

  const AddExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class UpdateExpenseEvent extends FinanceEvent {
  final ExpenseModel expense;

  const UpdateExpenseEvent(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpenseEvent extends FinanceEvent {
  final String id;
  final String businessId;

  const DeleteExpenseEvent(this.id, this.businessId);

  @override
  List<Object?> get props => [id, businessId];
}
