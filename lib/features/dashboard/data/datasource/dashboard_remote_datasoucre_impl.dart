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
    print("current user id:-$currentuserid");
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
          .toList();
      if (businessIds.isNotEmpty) {
        bizResponse = await supabaseClient
            .from('businesses')
            .select()
            .inFilter('id', businessIds);
      }
    }

    print("Business:-${bizResponse}");
    final totalBusinesses = bizResponse.length;
    final businessIds = bizResponse.map((e) => e['id']).toList();

    // 2. Fetch pending tasks
    var taskQuery = supabaseClient
        .from('tasks')
        .select()
        .inFilter("business_id", businessIds)
        .eq('status', 'Pending');
    // if (businessId != null) {
    //   taskQuery = taskQuery.eq('business_id', businessId);
    // }
    final taskResponse = await taskQuery;
    final pendingTasks = taskResponse.length;

    // 3. Fetch financial stats using business_profit_loss view
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    double totalProfit = 0.0;

    var profitLossQuery = supabaseClient
        .from('business_profit_loss')
        .select()
        .inFilter("business_id", businessIds);
    // if (businessId != null) {
    //   profitLossQuery = profitLossQuery.eq('business_id', businessId);
    // }
    final profitLossResponse = await profitLossQuery;

    for (var row in profitLossResponse) {
      totalIncome += (row['total_income'] as num?)?.toDouble() ?? 0.0;
      totalExpense += (row['total_expense'] as num?)?.toDouble() ?? 0.0;
      totalProfit += (row['net_profit'] as num?)?.toDouble() ?? 0.0;
    }

    // 4. Fetch recent activities from activities table
    var activitiesQuery = supabaseClient
        .from('activities')
        .select()
        .inFilter("business_id", businessIds);

    // if (businessId != null) {
    //   activitiesQuery = activitiesQuery.eq('business_id', businessId);
    // }

    final activitiesResponse = await activitiesQuery
        .order('created_at', ascending: false)
        .limit(15);

    final recentActivities = activitiesResponse.map((row) {
      final title = row['title'] as String;
      final createdAt = DateTime.parse(row['created_at'] as String);
      final rawDesc = row['description'] as String? ?? '';

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

      return {
        'type': type,
        'title': title,
        'subtitle': desc,
        'amount': amount,
        'date': createdAt,
        'tag': type == 'income' ? 'INFLOW' : 'OUTFLOW',
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

      await supabaseClient.from('activities').insert({
        'id': uuid,
        'business_id': businessId,
        'title': title,
        'description': fullDesc,
      });
    } catch (e) {
      print("Warning: failed to log activity: $e");
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
      final activities = await supabaseClient
          .from('activities')
          .select()
          .eq('business_id', businessId)
          .order('created_at', ascending: false)
          .limit(15);

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
        final title = row['title'] as String;
        final createdAt = DateTime.parse(row['created_at'] as String);
        final rawDesc = row['description'] as String? ?? '';

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

        return {
          'type': type,
          'title': title,
          'subtitle': desc,
          'amount': amount,
          'date': createdAt,
          'tag': type == 'income' ? 'INFLOW' : 'OUTFLOW',
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
