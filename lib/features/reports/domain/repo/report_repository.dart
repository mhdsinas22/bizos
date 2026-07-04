import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

abstract class ReportRepository {
  Future<List<IncomeModel>> getIncomeReportData(String businessId);
  Future<List<ExpenseModel>> getExpenseReportData(String businessId);
  Future<List<TaskModel>> getTaskReportData(String businessId);
}
