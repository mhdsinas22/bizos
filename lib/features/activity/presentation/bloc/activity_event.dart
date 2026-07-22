abstract class ActivityEvent {}

class FetchActivitiesEvent extends ActivityEvent {
  final bool isRefresh;
  FetchActivitiesEvent({this.isRefresh = false});
}

class LoadMoreActivitiesEvent extends ActivityEvent {}

class FilterChangedEvent extends ActivityEvent {
  final bool? isPersonal;
  final String? businessId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final String? selectedDateFilter;

  FilterChangedEvent({
    this.isPersonal,
    this.businessId,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.selectedDateFilter,
  });
}
