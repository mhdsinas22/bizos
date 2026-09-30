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
  Future<List<IncomeModel>> getIncomeList(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await incomeRemoteDatasource.getIncomeList(
      businessId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<IncomeModel>> getAllIncome() async {
    return await incomeRemoteDatasource.getAllIncome();
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    await incomeRemoteDatasource.addIncome(income);
    // Automatically log activity
    await activityRepository.logActivity(
      businessId: income.businessId,
      title: "Income Added",
      description:
          "Category: ${income.category} | Method: ${income.paymentMethod} | Amount: ${income.amount} | Description: ${income.description}",
      module: "Income",
      action: "Add",
      referenceId: income.id,
      createdBy: income.createdByUserId,
    );
  }

  @override
  Future<void> updateIncome(IncomeModel income) async {
    await incomeRemoteDatasource.updateIncome(income);
    // Automatically log activity
    await activityRepository.logActivity(
      businessId: income.businessId,
      title: "Income Updated",
      description:
          "Category: ${income.category} | Method: ${income.paymentMethod} | Amount: ${income.amount} | Description: ${income.description}",
      module: "Income",
      action: "Update",
      referenceId: income.id,
      createdBy: income.createdByUserId,
    );
  }

  @override
  Future<void> deleteIncome(String id) async {
    final deleted = await incomeRemoteDatasource.deleteIncome(id);
    if (deleted != null) {
      // Automatically log activity
      await activityRepository.logActivity(
        businessId: deleted.businessId,
        title: "Income Deleted",
        description:
            "Category: ${deleted.category} | Method: ${deleted.paymentMethod} | Amount: ${deleted.amount} | Description: ${deleted.description}",
        module: "Income",
        action: "Delete",
        referenceId: deleted.id,
        createdBy: deleted.createdByUserId,
      );
    }
  }
}
