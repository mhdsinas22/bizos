import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';

class AddPaymentHistoryUseCase {
  final MoneyManagementRepository repository;

  AddPaymentHistoryUseCase(this.repository);

  Future<MoneyTransactionHistoryEntity> execute({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required String notes,
    required bool isPersonal,
    String? createdBy,
  }) {
    return repository.addPaymentHistory(
      transactionId: transactionId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      isPersonal: isPersonal,
      createdBy: createdBy,
    );
  }
}
