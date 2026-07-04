import 'package:bizos/features/finance/data/datasoucre/income_remote_datasource.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeRemoteDatasource incomeRemoteDatasource;
  final DashboardRemoteDatasource dashboardRemoteDatasource;

  IncomeRepositoryImpl({
    required this.incomeRemoteDatasource,
    required this.dashboardRemoteDatasource,
  });

  @override
  Future<List<IncomeModel>> getIncomeList(String businessId) async {
    try {
      return await incomeRemoteDatasource.getIncomeList(businessId);
    } catch (e) {
      print("Error fetching income list: $e");
      rethrow;
    }
  }

  @override
  Future<List<IncomeModel>> getAllIncome() async {
    try {
      return await incomeRemoteDatasource.getAllIncome();
    } catch (e) {
      print("Error fetching all income: $e");
      rethrow;
    }
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    try {
      await incomeRemoteDatasource.addIncome(income);
      // Automatically log activity
      await dashboardRemoteDatasource.logActivity(
        businessId: income.businessId,
        title: "Add Income",
        description:
            "Received Income: ${income.category} - ${income.description}",
        amount: income.amount,
      );
    } catch (e) {
      print("Error adding income: $e");
      rethrow;
    }
  }

  @override
  Future<void> updateIncome(IncomeModel income) async {
    try {
      await incomeRemoteDatasource.updateIncome(income);
    } catch (e) {
      print("Error updating income: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      await incomeRemoteDatasource.deleteIncome(id);
    } catch (e) {
      print("Error deleting income: $e");
      rethrow;
    }
  }
}
