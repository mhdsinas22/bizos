import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/reports/data/datasource/report_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRemoteDatasourceImpl implements ReportRemoteDatasource {
  final SupabaseClient supabaseClient;

  ReportRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<List<IncomeModel>> getIncomeReportData(String businessId) async {
    final response = await supabaseClient
        .from('incomes')
        .select()
        .eq('business_id', businessId);

    return response.map((row) => _fromIncomeRow(row)).toList();
  }

  @override
  Future<List<ExpenseModel>> getExpenseReportData(String businessId) async {
    final response = await supabaseClient
        .from('expenses')
        .select()
        .eq('business_id', businessId);

    return response.map((row) => _fromExpenseRow(row)).toList();
  }

  @override
  Future<List<TaskModel>> getTaskReportData(String businessId) async {
    final response = await supabaseClient
        .from('tasks')
        .select()
        .eq('business_id', businessId);

    return response.map((row) => _fromTaskRow(row)).toList();
  }

  IncomeModel _fromIncomeRow(Map<String, dynamic> row) {
    return IncomeModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      description: row['description'] ?? '',
      date: DateTime.parse(row['income_date'] as String),
      createdByUserId: row['created_by_user_id'] as String?,
      createdByName: row['created_by_name'] as String?,
    );
  }

  ExpenseModel _fromExpenseRow(Map<String, dynamic> row) {
    return ExpenseModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      description: row['description'] ?? '',
      date: DateTime.parse(row['expense_date'] as String),
      createdByUserId: row['created_by_user_id'] as String?,
      createdByName: row['created_by_name'] as String?,
    );
  }

  TaskModel _fromTaskRow(Map<String, dynamic> row) {
    return TaskModel(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      title: row['title'] as String,
      description: row['description'] ?? '',
      priority: row['priority'] ?? 'Medium',
      dueDate: DateTime.parse(row['due_date'] as String),
      isCompleted: (row['status'] as String).toLowerCase() == 'completed',
      assignedto: row["assigned_to"]?.toString() ?? "",
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'])
          : DateTime.now(),
      createdBy: row['created_by']?.toString() ?? "",
      ownerId: row['owner_id']?.toString() ?? "",
    );
  }
}
