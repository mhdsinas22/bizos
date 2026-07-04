import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:equatable/equatable.dart';

abstract class PersonalExpenseState extends Equatable {
  const PersonalExpenseState();

  @override
  List<Object?> get props => [];
}

class PersonalExpenseInitial extends PersonalExpenseState {}

class PersonalExpenseLoading extends PersonalExpenseState {}

class PersonalExpenseLoaded extends PersonalExpenseState {
  final List<PersonalExpenseEntity> expenses;
  final List<PersonalExpenseEntity> filteredExpenses;
  final double totalExpense;
  final double monthlyExpense;
  final double todayExpense;
  final String highestCategory;
  final Map<String, double> categoryAnalytics;
  final Map<String, double> monthlyTrend;
  final String currentFilter; // 'today', 'week', 'month', 'year', 'custom', 'all'
  final String currentSort; // 'newest', 'oldest', 'highest', 'lowest'
  final String searchQuery;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const PersonalExpenseLoaded({
    required this.expenses,
    required this.filteredExpenses,
    required this.totalExpense,
    required this.monthlyExpense,
    required this.todayExpense,
    required this.highestCategory,
    required this.categoryAnalytics,
    required this.monthlyTrend,
    this.currentFilter = 'all',
    this.currentSort = 'newest',
    this.searchQuery = '',
    this.customStartDate,
    this.customEndDate,
  });

  PersonalExpenseLoaded copyWith({
    List<PersonalExpenseEntity>? expenses,
    List<PersonalExpenseEntity>? filteredExpenses,
    double? totalExpense,
    double? monthlyExpense,
    double? todayExpense,
    String? highestCategory,
    Map<String, double>? categoryAnalytics,
    Map<String, double>? monthlyTrend,
    String? currentFilter,
    String? currentSort,
    String? searchQuery,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return PersonalExpenseLoaded(
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      totalExpense: totalExpense ?? this.totalExpense,
      monthlyExpense: monthlyExpense ?? this.monthlyExpense,
      todayExpense: todayExpense ?? this.todayExpense,
      highestCategory: highestCategory ?? this.highestCategory,
      categoryAnalytics: categoryAnalytics ?? this.categoryAnalytics,
      monthlyTrend: monthlyTrend ?? this.monthlyTrend,
      currentFilter: currentFilter ?? this.currentFilter,
      currentSort: currentSort ?? this.currentSort,
      searchQuery: searchQuery ?? this.searchQuery,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }

  @override
  List<Object?> get props => [
        expenses,
        filteredExpenses,
        totalExpense,
        monthlyExpense,
        todayExpense,
        highestCategory,
        categoryAnalytics,
        monthlyTrend,
        currentFilter,
        currentSort,
        searchQuery,
        customStartDate,
        customEndDate,
      ];
}

class PersonalExpenseError extends PersonalExpenseState {
  final String message;

  const PersonalExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
