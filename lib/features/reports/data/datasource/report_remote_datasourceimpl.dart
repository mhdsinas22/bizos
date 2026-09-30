import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/reports/data/datasource/report_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRemoteDatasourceImpl implements ReportRemoteDatasource {
  final SupabaseClient supabaseClient;

  ReportRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<IncomeModel>> getIncomeReportData(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bId = businessId.trim();
    if (bId.isEmpty) return [];
    AppLogger.info("📊 [ReportDatasource] Fetching Canonical Income Data for Business ID: '$bId' (Range: $startDate to $endDate)");

    try {
      var query = supabaseClient
          .from('incomes')
          .select()
          .eq('business_id', bId);

      if (startDate != null) {
        query = query.gte('income_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('income_date', endDate.toIso8601String());
      }

      final response = await query.order('income_date', ascending: false);

      final directIncomes = (response as List<dynamic>)
          .map((row) => _fromIncomeRow(row as Map<String, dynamic>))
          .toList();

      AppLogger.info("📊 [ReportDatasource] Loaded ${directIncomes.length} canonical income records from 'incomes'.");
      return directIncomes;
    } catch (e) {
      AppLogger.error("⚠️ [ReportDatasource] Error fetching 'incomes': $e");
      rethrow;
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenseReportData(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final bId = businessId.trim();
    if (bId.isEmpty) return [];
    AppLogger.info("📊 [ReportDatasource] Fetching Canonical Expense Data for Business ID: '$bId' (Range: $startDate to $endDate)");

    try {
      var query = supabaseClient
          .from('expenses')
          .select()
          .eq('business_id', bId);

      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String());
      }

      final response = await query.order('expense_date', ascending: false);

      final directExpenses = (response as List<dynamic>)
          .map((row) => _fromExpenseRow(row as Map<String, dynamic>))
          .toList();

      AppLogger.info("📊 [ReportDatasource] Loaded ${directExpenses.length} canonical expense records from 'expenses'.");
      return directExpenses;
    } catch (e) {
      AppLogger.error("⚠️ [ReportDatasource] Error fetching 'expenses': $e");
      rethrow;
    }
  }

  @override
  Future<List<TaskModel>> getTaskReportData(String businessId) async {
    final bId = businessId.trim();
    try {
      final response = await supabaseClient
          .from('tasks')
          .select()
          .eq('business_id', bId);

      return (response as List<dynamic>)
          .map((row) => _fromTaskRow(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error("⚠️ [ReportDatasource] Error fetching tasks: $e");
      return [];
    }
  }

  IncomeModel _fromIncomeRow(Map<String, dynamic> row) {
    return IncomeModel.fromMap(row);
  }

  ExpenseModel _fromExpenseRow(Map<String, dynamic> row) {
    return ExpenseModel.fromMap(row);
  }

  TaskModel _fromTaskRow(Map<String, dynamic> row) {
    return TaskModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      title: row['title'] as String,
      description: row['description'] ?? '',
      priority: row['priority'] ?? 'Medium',
      dueDate: TaskModel.parseDueDate(row['due_date']),
      isCompleted: (row['status'] as String).toLowerCase() == 'completed',
      assignedto: row["assigned_to"]?.toString() ?? "",
      createdAt: row['created_at'] != null
          ? TaskModel.parseDueDate(row['created_at'])
          : DateTime.now(),
      createdBy: row['created_by']?.toString() ?? "",
      ownerId: row['owner_id']?.toString() ?? "",
    );
  }
}
