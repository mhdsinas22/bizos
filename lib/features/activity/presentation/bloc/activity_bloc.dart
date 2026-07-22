import 'package:bizos/features/activity/domain/entities/activity_entity.dart';
import 'package:bizos/features/activity/domain/usecases/get_activities.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_event.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_state.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final GetActivities getActivities;
  final AuthBloc authBloc;
  static const int _limit = 20;

  ActivityBloc({required this.getActivities, required this.authBloc})
      : super(const ActivityState()) {
    on<FetchActivitiesEvent>(_onFetchActivities);
    on<LoadMoreActivitiesEvent>(_onLoadMoreActivities);
    on<FilterChangedEvent>(_onFilterChanged);
  }

  Future<void> _onFetchActivities(
    FetchActivitiesEvent event,
    Emitter<ActivityState> emit,
  ) async {
    final user = _getAuthenticatedUser();
    if (user == null) {
      emit(state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        hasError: true,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    if (event.isRefresh) {
      emit(state.copyWith(
        isRefreshing: true,
        hasError: false,
        errorMessage: null,
      ));
    } else {
      emit(state.copyWith(
        isInitialLoading: true,
        hasError: false,
        errorMessage: null,
      ));
    }

    try {
      final activities = await _fetchActivitiesFromRepository(
        user: user,
        isPersonal: state.isPersonal,
        businessId: state.businessId,
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
        page: 1,
      );

      emit(state.copyWith(
        activities: activities,
        hasReachedMax: activities.length < _limit,
        isInitialLoading: false,
        isRefreshing: false,
        page: 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        hasError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreActivities(
    LoadMoreActivitiesEvent event,
    Emitter<ActivityState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.isInitialLoading ||
        state.isRefreshing) {
      return;
    }

    final user = _getAuthenticatedUser();
    if (user == null) {
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    emit(state.copyWith(
      isLoadingMore: true,
      hasError: false,
      errorMessage: null,
    ));

    final nextPage = state.page + 1;

    try {
      final newActivities = await _fetchActivitiesFromRepository(
        user: user,
        isPersonal: state.isPersonal,
        businessId: state.businessId,
        startDate: state.startDate,
        endDate: state.endDate,
        searchQuery: state.searchQuery,
        page: nextPage,
      );

      emit(state.copyWith(
        activities: state.activities + newActivities,
        hasReachedMax: newActivities.length < _limit,
        isLoadingMore: false,
        page: nextPage,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        hasError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFilterChanged(
    FilterChangedEvent event,
    Emitter<ActivityState> emit,
  ) async {
    final user = _getAuthenticatedUser();
    if (user == null) {
      emit(state.copyWith(
        hasError: true,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    final isPersonal = event.isPersonal ?? state.isPersonal;
    final businessId = event.businessId ??
        (event.isPersonal == true ? null : state.businessId);

    DateTime? startDate = state.startDate;
    DateTime? endDate = state.endDate;
    bool shouldClearDates = false;

    if (event.startDate != null || event.endDate != null) {
      startDate = event.startDate;
      endDate = event.endDate;
    } else if (event.startDate == null &&
        event.endDate == null &&
        (event.isPersonal != null ||
            event.businessId != null ||
            event.searchQuery != null)) {
      // Keep existing dates
    } else {
      // Explicit reset
      startDate = null;
      endDate = null;
      shouldClearDates = true;
    }

    final searchQuery = event.searchQuery ?? state.searchQuery;
    final selectedDateFilter = event.selectedDateFilter ??
        (shouldClearDates ? 'All' : state.selectedDateFilter);

    emit(state.copyWith(
      isInitialLoading: true,
      hasError: false,
      errorMessage: null,
      isPersonal: isPersonal,
      businessId: businessId,
      startDate: startDate,
      endDate: endDate,
      clearDates: shouldClearDates,
      searchQuery: searchQuery,
      selectedDateFilter: selectedDateFilter,
    ));

    try {
      final activities = await _fetchActivitiesFromRepository(
        user: user,
        isPersonal: isPersonal,
        businessId: businessId,
        startDate: startDate,
        endDate: endDate,
        searchQuery: searchQuery,
        page: 1,
      );

      emit(state.copyWith(
        activities: activities,
        hasReachedMax: activities.length < _limit,
        isInitialLoading: false,
        page: 1,
      ));
    } catch (e) {
      emit(state.copyWith(
        isInitialLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  UserModel? _getAuthenticatedUser() {
    final authState = authBloc.state;
    if (authState is Authenticated) {
      return authState.user;
    }
    return null;
  }

  Future<List<ActivityEntity>> _fetchActivitiesFromRepository({
    required UserModel user,
    required bool isPersonal,
    required String? businessId,
    required DateTime? startDate,
    required DateTime? endDate,
    required String searchQuery,
    required int page,
  }) {
    return getActivities(
      userId: user.id,
      isOwner: user.isOwner,
      isPersonal: isPersonal,
      businessId: businessId,
      assignedBusinessIds: user.businessPermissions.keys.toList(),
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery,
      page: page,
      limit: _limit,
    );
  }
}
