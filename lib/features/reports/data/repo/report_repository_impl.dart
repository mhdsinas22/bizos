import 'package:bizos/features/reports/data/datasource/report_remote_datasource.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/reports/domain/repo/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDatasource reportRemoteDatasource;

  ReportRepositoryImpl({required this.reportRemoteDatasource});

  @override
  Future<List<IncomeModel>> getIncomeReportData(String businessId) async {
    try {
      return await reportRemoteDatasource.getIncomeReportData(businessId);
    } catch (e) {
      print("Error fetching income report data: $e");
      rethrow;
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenseReportData(String businessId) async {
    try {
      return await reportRemoteDatasource.getExpenseReportData(businessId);
    } catch (e) {
      print("Error fetching expense report data: $e");
      rethrow;
    }
  }

  @override
  Future<List<TaskModel>> getTaskReportData(String businessId) async {
    try {
      return await reportRemoteDatasource.getTaskReportData(businessId);
    } catch (e) {
      print("Error fetching task report data: $e");
      rethrow;
    }
  }
}
