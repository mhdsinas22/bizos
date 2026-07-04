import 'package:bizos/features/finance/data/models/income_model.dart';

abstract class IncomeRemoteDatasource {
  Future<List<IncomeModel>> getIncomeList(String businessId);
  Future<List<IncomeModel>> getAllIncome();
  Future<void> addIncome(IncomeModel income);
  Future<void> updateIncome(IncomeModel income);
  Future<void> deleteIncome(String id);
}
