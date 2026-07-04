import 'package:bizos/features/finance/presentation/bloc/finace_state.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/finance/domain/repositories/income_repository.dart';
import 'package:bizos/features/finance/domain/repositories/expense_repository.dart';

// Events

// States

// BLoC
class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final IncomeRepository incomeRepository;
  final ExpenseRepository expenseRepository;

  FinanceBloc({required this.incomeRepository, required this.expenseRepository})
    : super(FinanceInitial()) {
    on<FetchFinanceDataEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        final incomes = await incomeRepository.getIncomeList(event.businessId);
        final expenses = await expenseRepository.getExpenseList(
          event.businessId,
        );
        // Sort by date descending
        incomes.sort((a, b) => b.date.compareTo(a.date));
        expenses.sort((a, b) => b.date.compareTo(a.date));
        emit(FinanceLoaded(incomes, expenses));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });

    on<AddIncomeEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        await incomeRepository.addIncome(event.income);
        add(FetchFinanceDataEvent(event.income.businessId));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });

    on<UpdateIncomeEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        await incomeRepository.updateIncome(event.income);
        add(FetchFinanceDataEvent(event.income.businessId));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });

    on<DeleteIncomeEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        await incomeRepository.deleteIncome(event.id);
        add(FetchFinanceDataEvent(event.businessId));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });

    on<AddExpenseEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        await expenseRepository.addExpense(event.expense);
        add(FetchFinanceDataEvent(event.expense.businessId));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });

    on<UpdateExpenseEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        await expenseRepository.updateExpense(event.expense);
        add(FetchFinanceDataEvent(event.expense.businessId));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });

    on<DeleteExpenseEvent>((event, emit) async {
      emit(FinanceLoading());
      try {
        await expenseRepository.deleteExpense(event.id);
        add(FetchFinanceDataEvent(event.businessId));
      } catch (e) {
        emit(FinanceError(e.toString()));
      }
    });
  }
}
