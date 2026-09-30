import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/reports/data/datasource/report_remote_datasource.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/data/models/expense_model.dart';
import 'package:bizos/features/task/data/models/task_model.dart';
import 'package:bizos/features/reports/domain/repo/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDatasource reportRemoteDatasource;

  ReportRepositoryImpl({required this.reportRemoteDatasource});

  @override
  Future<List<IncomeModel>> getIncomeReportData(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await reportRemoteDatasource.getIncomeReportData(
        businessId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      AppLogger.error("Error fetching income report data: $e");
      rethrow;
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenseReportData(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await reportRemoteDatasource.getExpenseReportData(
        businessId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      AppLogger.error("Error fetching expense report data: $e");
      rethrow;
    }
  }

  @override
  Future<List<TaskModel>> getTaskReportData(String businessId) async {
    try {
      return await reportRemoteDatasource.getTaskReportData(businessId);
    } catch (e) {
      AppLogger.error("Error fetching task report data: $e");
      rethrow;
    }
  }
}
