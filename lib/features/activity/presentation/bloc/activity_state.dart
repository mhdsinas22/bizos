import 'package:bizos/features/activity/domain/entities/activity_entity.dart';

class ActivityState {
  final List<ActivityEntity> activities;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasError;
  final bool hasReachedMax;
  final int page;
  final bool isPersonal;
  final String? businessId; // 'all' or specific ID
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final String selectedDateFilter;

  const ActivityState({
    this.activities = const [],
    this.isInitialLoading = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasError = false,
    this.hasReachedMax = false,
    this.page = 1,
    this.isPersonal = false,
    this.businessId = 'all',
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.selectedDateFilter = 'All',
  });

  ActivityState copyWith({
    List<ActivityEntity>? activities,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasError,
    bool? hasReachedMax,
    int? page,
    bool? isPersonal,
    String? businessId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String? selectedDateFilter,
    bool clearDates = false,
  }) {
    return ActivityState(
      activities: activities ?? this.activities,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: hasError == true ? errorMessage : (errorMessage ?? this.errorMessage),
      hasError: hasError ?? this.hasError,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      isPersonal: isPersonal ?? this.isPersonal,
      businessId: businessId ?? this.businessId,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
    );
  }
}
