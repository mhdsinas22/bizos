import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';

abstract class ReportRemoteDatasource {
  Future<List<IncomeModel>> getIncomeReportData(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<ExpenseModel>> getExpenseReportData(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<TaskModel>> getTaskReportData(String businessId);
}

