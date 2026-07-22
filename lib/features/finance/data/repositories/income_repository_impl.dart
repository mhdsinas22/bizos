import 'package:bizos/features/finance/data/datasoucre/income_remote_datasource.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/finance/data/models/income_model.dart';
import 'package:bizos/features/finance/domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final IncomeRemoteDatasource incomeRemoteDatasource;
  final ActivityRepository activityRepository;

  IncomeRepositoryImpl({
    required this.incomeRemoteDatasource,
    required this.activityRepository,
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
      await activityRepository.logActivity(
        businessId: income.businessId,
        title: "Income Added",
        description: "Category: ${income.category} | Amount: ${income.amount} | Description: ${income.description}",
        module: "Income",
        action: "Add",
        referenceId: income.id,
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
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: income.businessId,
        title: "Income Updated",
        description: "Category: ${income.category} | Amount: ${income.amount} | Description: ${income.description}",
        module: "Income",
        action: "Update",
        referenceId: income.id,
      );
    } catch (e) {
      print("Error updating income: $e");
      rethrow;
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    try {
      final deleted = await incomeRemoteDatasource.deleteIncome(id);
      if (deleted != null) {
        // Automatically log activity
        await activityRepository.logActivity(
          businessId: deleted.businessId,
          title: "Income Deleted",
          description: "Category: ${deleted.category} | Amount: ${deleted.amount} | Description: ${deleted.description}",
          module: "Income",
          action: "Delete",
          referenceId: deleted.id,
        );
      }
    } catch (e) {
      print("Error deleting income: $e");
      rethrow;
    }
  }
}
