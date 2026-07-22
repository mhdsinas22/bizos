import 'dart:async';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/widgets/empty_state.dart';
import 'package:bizos/features/activity/domain/entities/activity_entity.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_event.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_state.dart';
import 'package:bizos/features/activity/presentation/widgets/activity_card.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/bloc/business_state.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Sync search controller with existing search query in the Bloc state
    _searchController.text = context.read<ActivityBloc>().state.searchQuery;

    // Listen to changes to rebuild for search clear button visibility
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ActivityBloc>().add(LoadMoreActivitiesEvent());
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ActivityBloc>().add(FilterChangedEvent(searchQuery: query));
    });
  }

  void _setDateFilter(String filterLabel) async {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    if (filterLabel == 'Today') {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filterLabel == 'Yesterday') {
      final yest = now.subtract(const Duration(days: 1));
      start = DateTime(yest.year, yest.month, yest.day);
      end = DateTime(yest.year, yest.month, yest.day, 23, 59, 59);
    } else if (filterLabel == 'This Week') {
      final diff = now.weekday - 1;
      final startOfWeek = now.subtract(Duration(days: diff));
      start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filterLabel == 'This Month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filterLabel == 'This Year') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else if (filterLabel == 'Custom Range') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: AppTheme.primaryColor),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        start = picked.start;
        end = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        if (mounted) {
          context.read<ActivityBloc>().add(
            FilterChangedEvent(
              startDate: start,
              endDate: end,
              selectedDateFilter: 'Custom Range',
            ),
          );
        }
        return;
      } else {
        return;
      }
    } else {
      // All / Reset
      start = null;
      end = null;
    }

    if (mounted) {
      context.read<ActivityBloc>().add(
        FilterChangedEvent(
          startDate: start,
          endDate: end,
          selectedDateFilter: filterLabel,
        ),
      );
    }
  }

  Map<String, List<ActivityEntity>> _groupActivities(
    List<ActivityEntity> list,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final fourteenDaysAgo = today.subtract(const Duration(days: 14));

    final groups = <String, List<ActivityEntity>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Last Week': [],
      'Older': [],
    };

    for (var act in list) {
      final actDate = DateTime(
        act.createdAt.year,
        act.createdAt.month,
        act.createdAt.day,
      );
      if (actDate == today) {
        groups['Today']!.add(act);
      } else if (actDate == yesterday) {
        groups['Yesterday']!.add(act);
      } else if (actDate.isAfter(sevenDaysAgo)) {
        groups['This Week']!.add(act);
      } else if (actDate.isAfter(fourteenDaysAgo)) {
        groups['Last Week']!.add(act);
      } else {
        groups['Older']!.add(act);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Scroll to filters top or show filter configuration
            },
          ),
        ],
      ),
      body: BlocListener<ActivityBloc, ActivityState>(
        listenWhen: (previous, current) =>
            current.hasError &&
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: BlocBuilder<BusinessBloc, BusinessState>(
          builder: (context, businessState) {
            List<BusinessModel> businesses = [];
            final businessMap = <String, String>{};

            if (businessState is BusinessLoaded) {
              businesses = businessState.businesses;
              for (var b in businesses) {
                businessMap[b.id] = b.name;
              }
            }

            return BlocBuilder<ActivityBloc, ActivityState>(
              builder: (context, state) {
                if (state.isInitialLoading && state.activities.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.hasError && state.activities.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.errorMessage ?? 'An error occurred',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<ActivityBloc>().add(
                                FetchActivitiesEvent(isRefresh: false),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final grouped = _groupActivities(state.activities);

                return Column(
                  children: [
                    // Top Filters Section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Segment Button for Business / Personal
                          Row(
                            children: [
                              Expanded(
                                child: SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment<bool>(
                                      value: false,
                                      label: Text('Business'),
                                      icon: Icon(Icons.storefront),
                                    ),
                                    ButtonSegment<bool>(
                                      value: true,
                                      label: Text('Personal'),
                                      icon: Icon(Icons.person),
                                    ),
                                  ],
                                  selected: {state.isPersonal},
                                  onSelectionChanged: (val) {
                                    context.read<ActivityBloc>().add(
                                      FilterChangedEvent(
                                        isPersonal: val.first,
                                        businessId: val.first ? null : 'all',
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Business Dropdown (if Business selected)
                          if (!state.isPersonal) ...[
                            DropdownButtonFormField<String>(
                              value: state.businessId ?? 'all',
                              decoration: InputDecoration(
                                labelText: 'Filter by Business',
                                prefixIcon: const Icon(
                                  Icons.storefront_outlined,
                                ),
                                fillColor: isDark
                                    ? AppTheme.darkBg
                                    : AppTheme.lightBg,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Businesses'),
                                ),
                                ...businesses.map((b) {
                                  return DropdownMenuItem(
                                    value: b.id,
                                    child: Text(b.name),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  context.read<ActivityBloc>().add(
                                    FilterChangedEvent(businessId: val),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Search Field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search title, desc, staff...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<ActivityBloc>().add(
                                          FilterChangedEvent(searchQuery: ''),
                                        );
                                      },
                                    )
                                  : null,
                              fillColor: isDark
                                  ? AppTheme.darkBg
                                  : AppTheme.lightBg,
                            ),
                            onChanged: _onSearchChanged,
                          ),
                          const SizedBox(height: 12),

                          // Date Filter Chips Scrollable
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  [
                                    'All',
                                    'Today',
                                    'Yesterday',
                                    'This Week',
                                    'This Month',
                                    'This Year',
                                    'Custom Range',
                                  ].map((label) {
                                    final isSelected =
                                        state.selectedDateFilter == label;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        selectedColor: AppTheme.primaryColor
                                            .withOpacity(0.18),
                                        checkmarkColor: AppTheme.primaryColor,
                                        onSelected: (_) =>
                                            _setDateFilter(label),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    const Divider(height: 1),

                    // Activities List
                    Expanded(
                      child: state.activities.isEmpty
                          ? const Center(
                              child: EmptyState(
                                icon: Icons.history_outlined,
                                title: 'No Activities',
                                message:
                                    'No actions logged matching current filters.',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                context.read<ActivityBloc>().add(
                                  FetchActivitiesEvent(isRefresh: true),
                                );
                              },
                              child: ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16.0),
                                itemCount:
                                    grouped.keys.length +
                                    (state.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == grouped.keys.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final groupKey = grouped.keys.elementAt(
                                    index,
                                  );
                                  final groupItems = grouped[groupKey]!;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Group Header
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 12.0,
                                          bottom: 8.0,
                                        ),
                                        child: Text(
                                          groupKey.toUpperCase(),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                      ),

                                      // Items in Group
                                      ...groupItems.map((act) {
                                        final bName = act.businessId != null
                                            ? businessMap[act.businessId]
                                            : null;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: ActivityCard(
                                            activity: act,
                                            businessName: bName,
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
