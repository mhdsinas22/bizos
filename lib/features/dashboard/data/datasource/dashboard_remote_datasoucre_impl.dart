import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DashboardRemoteDatasourceImpl implements DashboardRemoteDatasource {
  final SupabaseClient supabaseClient;

  DashboardRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<DashboardData> getDashboardData(
    String? businessId,
    String currentuserid,
  ) async {
    final emptyData = DashboardData(
      totalBusinesses: 0,
      totalIncome: 0.0,
      totalExpense: 0.0,
      totalProfit: 0.0,
      pendingTasks: 0,
      recentActivities: [],
      monthlySummary: {},
    );
    if (currentuserid.trim().isEmpty) return emptyData;

    // 1. Fetch total businesses
    // Fetch user profile to determine role
    final userResponse = await supabaseClient
        .from('users')
        .select('role')
        .eq('id', currentuserid)
        .maybeSingle();

    final role = (userResponse?['role'] as String?)?.toLowerCase() ?? 'owner';

    List<dynamic> bizResponse = [];
    if (role == 'owner') {
      bizResponse = await supabaseClient
          .from('businesses')
          .select()
          .eq("owner_id", currentuserid);
    } else {
      final assignedResponse = await supabaseClient
          .from('staff_businesses')
          .select('business_id')
          .eq('staff_id', currentuserid);
      final businessIds = assignedResponse
          .map((row) => row['business_id'] as String)
          .where((id) => id.trim().isNotEmpty)
          .toList();
      if (businessIds.isNotEmpty) {
        bizResponse = await supabaseClient
            .from('businesses')
            .select()
            .inFilter('id', businessIds);
      }
    }

    final totalBusinesses = bizResponse.length;
    final businessIds = bizResponse
        .map((e) => e['id']?.toString() ?? '')
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    if (businessIds.isEmpty) return emptyData;

    // 2. Fetch pending tasks
    final taskResponse = await supabaseClient
        .from('tasks')
        .select()
        .inFilter("business_id", businessIds)
        .eq('status', 'Pending');
    final pendingTasks = taskResponse.length;

    // 3. Fetch financial stats directly from incomes and expenses tables
    final incomesResponse = await supabaseClient
        .from('incomes')
        .select('business_id, amount')
        .inFilter('business_id', businessIds);

    final expensesResponse = await supabaseClient
        .from('expenses')
        .select('business_id, amount')
        .inFilter('business_id', businessIds);

    final Map<String, double> incomePerBusiness = {};
    final Map<String, double> expensePerBusiness = {};

    for (var row in (incomesResponse as List<dynamic>)) {
      final bId = row['business_id'] as String;
      final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
      incomePerBusiness[bId] = (incomePerBusiness[bId] ?? 0.0) + amt;
    }

    for (var row in (expensesResponse as List<dynamic>)) {
      final bId = row['business_id'] as String;
      final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
      expensePerBusiness[bId] = (expensePerBusiness[bId] ?? 0.0) + amt;
    }

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final bId in businessIds) {
      final inc = incomePerBusiness[bId] ?? 0.0;
      final exp = expensePerBusiness[bId] ?? 0.0;
      totalIncome += inc;
      totalExpense += exp;
      AppLogger.info(
        '[DEBUG DASHBOARD] business id: $bId | income total per business: $inc | expense total per business: $exp',
      );
    }

    final double totalProfit = totalIncome - totalExpense;
    AppLogger.info(
      '[DEBUG DASHBOARD] final aggregated total -> totalIncome: $totalIncome | totalExpense: $totalExpense | totalProfit: $totalProfit',
    );

    // 4. Fetch recent activities from activities table
    List<dynamic> activitiesResponse = [];
    try {
      activitiesResponse = await supabaseClient
          .from('activities')
          .select('*, users:created_by(name)')
          .inFilter("business_id", businessIds)
          .order('created_at', ascending: false)
          .limit(15);
    } catch (_) {
      activitiesResponse = await supabaseClient
          .from('activities')
          .select()
          .inFilter("business_id", businessIds)
          .order('created_at', ascending: false)
          .limit(15);
    }

    final missingUserIds = (activitiesResponse)
        .map((row) => (row as Map)['created_by'] as String?)
        .where((id) => id != null && id.trim().isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    Map<String, String> userNamesMap = {};
    if (missingUserIds.isNotEmpty) {
      try {
        final usersResp = await supabaseClient
            .from('users')
            .select('id, name')
            .inFilter('id', missingUserIds);
        for (var u in (usersResp as List)) {
          final uid = u['id'] as String;
          final uname = (u['name'] as String?)?.trim() ?? 'Unknown User';
          userNamesMap[uid] = uname.isNotEmpty ? uname : 'Unknown User';
        }
      } catch (_) {}
    }

    final recentActivities = activitiesResponse.map((row) {
      final map = row as Map<String, dynamic>;
      final title = map['title'] as String? ?? '';
      final createdAt =
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now();
      final rawDesc = map['description'] as String? ?? '';

      final parts = rawDesc.split('|');
      final desc = parts.isNotEmpty ? parts[0] : '';
      final amount = parts.length > 1 ? double.tryParse(parts[1]) ?? 0.0 : 0.0;

      final type =
          (title.toLowerCase().contains('income') ||
              title.toLowerCase().contains('received'))
          ? 'income'
          : (title.toLowerCase().contains('expense') ||
                    title.toLowerCase().contains('logged')
                ? 'expense'
                : 'other');

      String actorName = 'Unknown User';
      if (map['users'] != null) {
        if (map['users'] is Map) {
          actorName =
              (map['users']['name'] as String?)?.trim() ?? 'Unknown User';
        } else if (map['users'] is List && (map['users'] as List).isNotEmpty) {
          actorName =
              ((map['users'] as List).first['name'] as String?)?.trim() ??
              'Unknown User';
        }
      } else if (map['created_by'] != null) {
        actorName = userNamesMap[map['created_by']] ?? 'Unknown User';
      }

      return {
        'id': map['id'] as String? ?? '',
        'business_id': map['business_id'] as String?,
        'type': type,
        'title': title,
        'subtitle': desc,
        'amount': amount,
        'date': createdAt,
        'tag': type == 'income' ? 'INFLOW' : 'OUTFLOW',
        'created_by': map['created_by'] as String? ?? '',
        'created_by_name': actorName,
        'module': map['module'] as String? ?? type,
        'action': map['action'] as String? ?? '',
        'description': rawDesc,
      };
    }).toList();

    // 5. Compile monthly summary flow
    // Fetch all incomes and expenses (filter by businessId if provided)
    var incomeQuery = supabaseClient
        .from('incomes')
        .select('income_date, amount')
        .inFilter("business_id", businessIds);
    var expenseQuery = supabaseClient
        .from('expenses')
        .select('expense_date, amount')
        .inFilter("business_id", businessIds);

    final incomesList = await incomeQuery;
    final expensesList = await expenseQuery;

    final summary = <String, Map<String, double>>{};

    for (var inc in incomesList) {
      final date = DateTime.parse(inc['income_date'] as String);
      final amt = (inc['amount'] as num).toDouble();
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      summary.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
      summary[key]!['income'] = summary[key]!['income']! + amt;
    }

    for (var exp in expensesList) {
      final date = DateTime.parse(exp['expense_date'] as String);
      final amt = (exp['amount'] as num).toDouble();
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      summary.putIfAbsent(key, () => {'income': 0.0, 'expense': 0.0});
      summary[key]!['expense'] = summary[key]!['expense']! + amt;
    }

    return DashboardData(
      totalBusinesses: totalBusinesses,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalProfit: totalProfit,
      pendingTasks: pendingTasks,
      recentActivities: recentActivities,
      monthlySummary: summary,
    );
  }

  @override
  Future<void> logActivity({
    String? businessId,
    required String title,
    required String description,
    required double amount,
  }) async {
    try {
      final uuid = const Uuid().v4();
      final fullDesc = '$description|$amount';
      final userId = supabaseClient.auth.currentUser?.id;

      await supabaseClient.from('activities').insert({
        'id': uuid,
        'business_id': businessId,
        'title': title,
        'description': fullDesc,
        'created_by': userId,
      });
    } catch (e) {
      AppLogger.error("Warning: failed to log activity: $e");
    }
  }

  @override
  Future<DashboardData> getSpecificBusinessData(String businessId) async {
    try {
      // Income
      final incomes = await supabaseClient
          .from('incomes')
          .select('amount,income_date')
          .eq('business_id', businessId);

      // Expense
      final expenses = await supabaseClient
          .from('expenses')
          .select('amount,expense_date')
          .eq('business_id', businessId);

      // Pending Tasks
      final tasks = await supabaseClient
          .from('tasks')
          .select()
          .eq('business_id', businessId)
          .eq('status', 'Pending');

      // Activities
      List<dynamic> activities = [];
      try {
        activities = await supabaseClient
            .from('activities')
            .select('*, users:created_by(name)')
            .eq('business_id', businessId)
            .order('created_at', ascending: false)
            .limit(15);
      } catch (_) {
        activities = await supabaseClient
            .from('activities')
            .select()
            .eq('business_id', businessId)
            .order('created_at', ascending: false)
            .limit(15);
      }

      final missingUserIds = (activities)
          .map((row) => (row as Map)['created_by'] as String?)
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      Map<String, String> userNamesMap = {};
      if (missingUserIds.isNotEmpty) {
        try {
          final usersResp = await supabaseClient
              .from('users')
              .select('id, name')
              .inFilter('id', missingUserIds);
          for (var u in (usersResp as List)) {
            final uid = u['id'] as String;
            final uname = (u['name'] as String?)?.trim() ?? 'Unknown User';
            userNamesMap[uid] = uname.isNotEmpty ? uname : 'Unknown User';
          }
        } catch (_) {}
      }

      double totalIncome = 0;
      double totalExpense = 0;

      for (final item in incomes) {
        totalIncome += (item['amount'] as num?)?.toDouble() ?? 0;
      }

      for (final item in expenses) {
        totalExpense += (item['amount'] as num?)?.toDouble() ?? 0;
      }

      final totalProfit = totalIncome - totalExpense;

      final recentActivities = activities.map((row) {
        final map = row as Map<String, dynamic>;
        final title = map['title'] as String? ?? '';
        final createdAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now();
        final rawDesc = map['description'] as String? ?? '';

        final parts = rawDesc.split('|');
        final desc = parts.isNotEmpty ? parts[0] : '';
        final amount = parts.length > 1
            ? double.tryParse(parts[1]) ?? 0.0
            : 0.0;

        final type =
            (title.toLowerCase().contains('income') ||
                title.toLowerCase().contains('received'))
            ? 'income'
            : (title.toLowerCase().contains('expense') ||
                      title.toLowerCase().contains('logged')
                  ? 'expense'
                  : 'other');

        String actorName = 'Unknown User';
        if (map['users'] != null) {
          if (map['users'] is Map) {
            actorName =
                (map['users']['name'] as String?)?.trim() ?? 'Unknown User';
          } else if (map['users'] is List &&
              (map['users'] as List).isNotEmpty) {
            actorName =
                ((map['users'] as List).first['name'] as String?)?.trim() ??
                'Unknown User';
          }
        } else if (map['created_by'] != null) {
          actorName = userNamesMap[map['created_by']] ?? 'Unknown User';
        }

        return {
          'id': map['id'] as String? ?? '',
          'business_id': map['business_id'] as String?,
          'type': type,
          'title': title,
          'subtitle': desc,
          'amount': amount,
          'date': createdAt,
          'tag': type == 'income' ? 'INFLOW' : 'OUTFLOW',
          'created_by': map['created_by'] as String? ?? '',
          'created_by_name': actorName,
          'module': map['module'] as String? ?? type,
          'action': map['action'] as String? ?? '',
          'description': rawDesc,
        };
      }).toList();

      final monthlySummary = <String, Map<String, double>>{};

      for (final inc in incomes) {
        final date = DateTime.parse(inc['income_date']);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        monthlySummary.putIfAbsent(key, () => {'income': 0, 'expense': 0});

        monthlySummary[key]!['income'] =
            monthlySummary[key]!['income']! + (inc['amount'] as num).toDouble();
      }

      for (final exp in expenses) {
        final date = DateTime.parse(exp['expense_date']);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        monthlySummary.putIfAbsent(key, () => {'income': 0, 'expense': 0});

        monthlySummary[key]!['expense'] =
            monthlySummary[key]!['expense']! +
            (exp['amount'] as num).toDouble();
      }

      return DashboardData(
        totalBusinesses: 1,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        totalProfit: totalProfit,
        pendingTasks: tasks.length,
        recentActivities: recentActivities,
        monthlySummary: monthlySummary,
      );
    } catch (e) {
      throw Exception('Failed to load business dashboard: $e');
    }
  }
}
