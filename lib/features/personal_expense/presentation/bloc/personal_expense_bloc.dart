import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/domain/usecases/add_personal_expense_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/delete_personal_expense_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/get_category_analytics_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/get_filtered_expenses_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/get_personal_expenses_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/update_personal_expense_usecase.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalExpenseBloc extends Bloc<PersonalExpenseEvent, PersonalExpenseState> {
  final AddPersonalExpenseUseCase addUseCase;
  final UpdatePersonalExpenseUseCase updateUseCase;
  final DeletePersonalExpenseUseCase deleteUseCase;
  final GetPersonalExpensesUseCase getUseCase;
  final GetFilteredExpensesUseCase getFilteredUseCase;
  final GetCategoryAnalyticsUseCase getAnalyticsUseCase;

  PersonalExpenseBloc({
    required this.addUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.getUseCase,
    required this.getFilteredUseCase,
    required this.getAnalyticsUseCase,
  }) : super(PersonalExpenseInitial()) {
    on<LoadPersonalExpenses>((event, emit) async {
      emit(PersonalExpenseLoading());
      try {
        final expenses = await getUseCase.execute(event.userId);
        final loadedState = _buildLoadedState(
          expenses: expenses,
          currentFilter: 'all',
          currentSort: 'newest',
          searchQuery: '',
        );
        emit(loadedState);
      } catch (e) {
        emit(PersonalExpenseError(e.toString()));
      }
    });

    on<AddPersonalExpense>((event, emit) async {
      final currentState = state;
      String currentFilter = 'all';
      String currentSort = 'newest';
      String searchQuery = '';
      DateTime? customStart;
      DateTime? customEnd;

      if (currentState is PersonalExpenseLoaded) {
        currentFilter = currentState.currentFilter;
        currentSort = currentState.currentSort;
        searchQuery = currentState.searchQuery;
        customStart = currentState.customStartDate;
        customEnd = currentState.customEndDate;
      }

      emit(PersonalExpenseLoading());
      try {
        await addUseCase.execute(event.expense, event.userId);
        
        // Reload raw expenses based on the current filter to keep UI consistent
        final expenses = await _fetchExpensesForFilter(
          userId: event.userId,
          filterType: currentFilter,
          startDate: customStart,
          endDate: customEnd,
        );

        final loadedState = _buildLoadedState(
          expenses: expenses,
          currentFilter: currentFilter,
          currentSort: currentSort,
          searchQuery: searchQuery,
          customStartDate: customStart,
          customEndDate: customEnd,
        );
        emit(loadedState);
      } catch (e) {
        emit(PersonalExpenseError(e.toString()));
      }
    });

    on<UpdatePersonalExpense>((event, emit) async {
      final currentState = state;
      String currentFilter = 'all';
      String currentSort = 'newest';
      String searchQuery = '';
      DateTime? customStart;
      DateTime? customEnd;

      if (currentState is PersonalExpenseLoaded) {
        currentFilter = currentState.currentFilter;
        currentSort = currentState.currentSort;
        searchQuery = currentState.searchQuery;
        customStart = currentState.customStartDate;
        customEnd = currentState.customEndDate;
      }

      emit(PersonalExpenseLoading());
      try {
        await updateUseCase.execute(event.expense, event.userId);
        
        final expenses = await _fetchExpensesForFilter(
          userId: event.userId,
          filterType: currentFilter,
          startDate: customStart,
          endDate: customEnd,
        );

        final loadedState = _buildLoadedState(
          expenses: expenses,
          currentFilter: currentFilter,
          currentSort: currentSort,
          searchQuery: searchQuery,
          customStartDate: customStart,
          customEndDate: customEnd,
        );
        emit(loadedState);
      } catch (e) {
        emit(PersonalExpenseError(e.toString()));
      }
    });

    on<DeletePersonalExpense>((event, emit) async {
      final currentState = state;
      String currentFilter = 'all';
      String currentSort = 'newest';
      String searchQuery = '';
      DateTime? customStart;
      DateTime? customEnd;

      if (currentState is PersonalExpenseLoaded) {
        currentFilter = currentState.currentFilter;
        currentSort = currentState.currentSort;
        searchQuery = currentState.searchQuery;
        customStart = currentState.customStartDate;
        customEnd = currentState.customEndDate;
      }

      emit(PersonalExpenseLoading());
      try {
        await deleteUseCase.execute(event.expenseId, event.userId);
        
        final expenses = await _fetchExpensesForFilter(
          userId: event.userId,
          filterType: currentFilter,
          startDate: customStart,
          endDate: customEnd,
        );

        final loadedState = _buildLoadedState(
          expenses: expenses,
          currentFilter: currentFilter,
          currentSort: currentSort,
          searchQuery: searchQuery,
          customStartDate: customStart,
          customEndDate: customEnd,
        );
        emit(loadedState);
      } catch (e) {
        emit(PersonalExpenseError(e.toString()));
      }
    });

    on<FilterPersonalExpenses>((event, emit) async {
      emit(PersonalExpenseLoading());
      try {
        // Query Supabase for date filtering
        final expenses = await _fetchExpensesForFilter(
          userId: event.userId,
          filterType: event.filterType,
          startDate: event.startDate,
          endDate: event.endDate,
        );

        final loadedState = _buildLoadedState(
          expenses: expenses,
          currentFilter: event.filterType,
          currentSort: 'newest',
          searchQuery: '',
          customStartDate: event.startDate,
          customEndDate: event.endDate,
        );
        emit(loadedState);
      } catch (e) {
        emit(PersonalExpenseError(e.toString()));
      }
    });

    on<SearchPersonalExpenses>((event, emit) {
      final currentState = state;
      if (currentState is PersonalExpenseLoaded) {
        final filtered = _applyFilterSearchAndSort(
          rawExpenses: currentState.expenses,
          searchQuery: event.query,
          sortBy: currentState.currentSort,
        );
        
        emit(currentState.copyWith(
          filteredExpenses: filtered,
          searchQuery: event.query,
        ));
      }
    });

    on<SortPersonalExpenses>((event, emit) {
      final currentState = state;
      if (currentState is PersonalExpenseLoaded) {
        final filtered = _applyFilterSearchAndSort(
          rawExpenses: currentState.expenses,
          searchQuery: currentState.searchQuery,
          sortBy: event.sortBy,
        );

        emit(currentState.copyWith(
          filteredExpenses: filtered,
          currentSort: event.sortBy,
        ));
      }
    });

    on<LoadAnalytics>((event, emit) async {
      emit(PersonalExpenseLoading());
      try {
        final expenses = await getUseCase.execute(event.userId);
        final loadedState = _buildLoadedState(
          expenses: expenses,
          currentFilter: 'all',
          currentSort: 'newest',
          searchQuery: '',
        );
        emit(loadedState);
      } catch (e) {
        emit(PersonalExpenseError(e.toString()));
      }
    });
  }

  Future<List<PersonalExpenseEntity>> _fetchExpensesForFilter({
    required String userId,
    required String filterType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    DateTime? start;
    DateTime? end;
    final now = DateTime.now();

    if (filterType == 'today') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filterType == 'week') {
      start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
    } else if (filterType == 'month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    } else if (filterType == 'year') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59);
    } else if (filterType == 'custom') {
      start = startDate;
      end = endDate;
    }

    if (filterType == 'all') {
      return getUseCase.execute(userId);
    } else {
      return getFilteredUseCase.execute(userId, startDate: start, endDate: end);
    }
  }

  PersonalExpenseLoaded _buildLoadedState({
    required List<PersonalExpenseEntity> expenses,
    required String currentFilter,
    required String currentSort,
    required String searchQuery,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    // 1. Calculate general stats based on all expenses (raw)
    final now = DateTime.now();
    double todayExpense = 0.0;
    double monthlyExpense = 0.0;

    for (final e in expenses) {
      // Check today
      if (e.expenseDate.year == now.year &&
          e.expenseDate.month == now.month &&
          e.expenseDate.day == now.day) {
        todayExpense += e.amount;
      }
      // Check this month
      if (e.expenseDate.year == now.year && e.expenseDate.month == now.month) {
        monthlyExpense += e.amount;
      }
    }

    // 2. Filter & Sort for UI list representation
    final filtered = _applyFilterSearchAndSort(
      rawExpenses: expenses,
      searchQuery: searchQuery,
      sortBy: currentSort,
    );

    // 3. Total Expense of the current active filters
    double totalExpense = 0.0;
    for (final e in filtered) {
      totalExpense += e.amount;
    }

    // 4. Calculate Category Analytics based on filtered expenses
    final Map<String, double> categoryAnalytics = {};
    for (final e in filtered) {
      categoryAnalytics[e.category] = (categoryAnalytics[e.category] ?? 0.0) + e.amount;
    }

    // 5. Highest category
    String highestCategory = 'None';
    double highestAmt = 0.0;
    categoryAnalytics.forEach((category, amount) {
      if (amount > highestAmt) {
        highestAmt = amount;
        highestCategory = category;
      }
    });

    // 6. Monthly Trend
    final monthlyTrend = _calculateMonthlyTrend(expenses);

    return PersonalExpenseLoaded(
      expenses: expenses,
      filteredExpenses: filtered,
      totalExpense: totalExpense,
      monthlyExpense: monthlyExpense,
      todayExpense: todayExpense,
      highestCategory: highestCategory,
      categoryAnalytics: categoryAnalytics,
      monthlyTrend: monthlyTrend,
      currentFilter: currentFilter,
      currentSort: currentSort,
      searchQuery: searchQuery,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
  }

  List<PersonalExpenseEntity> _applyFilterSearchAndSort({
    required List<PersonalExpenseEntity> rawExpenses,
    required String searchQuery,
    required String sortBy,
  }) {
    List<PersonalExpenseEntity> result = List.from(rawExpenses);

    // 1. Search Filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((e) =>
          e.category.toLowerCase().contains(query) ||
          e.description.toLowerCase().contains(query)).toList();
    }

    // 2. Sorting
    if (sortBy == 'newest') {
      result.sort((a, b) {
        final cmp = b.expenseDate.compareTo(a.expenseDate);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
    } else if (sortBy == 'oldest') {
      result.sort((a, b) {
        final cmp = a.expenseDate.compareTo(b.expenseDate);
        if (cmp != 0) return cmp;
        return a.createdAt.compareTo(b.createdAt);
      });
    } else if (sortBy == 'highest') {
      result.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (sortBy == 'lowest') {
      result.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return result;
  }

  Map<String, double> _calculateMonthlyTrend(List<PersonalExpenseEntity> expenses) {
    final Map<String, double> trend = {
      'Jan': 0.0,
      'Feb': 0.0,
      'Mar': 0.0,
      'Apr': 0.0,
      'May': 0.0,
      'Jun': 0.0,
      'Jul': 0.0,
      'Aug': 0.0,
      'Sep': 0.0,
      'Oct': 0.0,
      'Nov': 0.0,
      'Dec': 0.0,
    };
    final currentYear = DateTime.now().year;
    final monthKeys = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (final exp in expenses) {
      if (exp.expenseDate.year == currentYear) {
        final monthIndex = exp.expenseDate.month - 1;
        if (monthIndex >= 0 && monthIndex < 12) {
          final key = monthKeys[monthIndex];
          trend[key] = (trend[key] ?? 0.0) + exp.amount;
        }
      }
    }
    return trend;
  }
}
