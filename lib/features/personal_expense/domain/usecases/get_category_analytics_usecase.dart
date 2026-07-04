import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';

class GetCategoryAnalyticsUseCase {
  final PersonalExpenseRepository repository;

  GetCategoryAnalyticsUseCase({required this.repository});

  Future<Map<String, double>> execute(String userId) async {
    return repository.getCategoryAnalytics(userId);
  }
}
