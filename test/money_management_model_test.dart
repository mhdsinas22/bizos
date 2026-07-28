import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_model.dart';
import 'package:bizos/features/money_management/data/models/debt_model.dart';
import 'package:bizos/features/money_management/data/models/money_transaction_history_model.dart';

void main() {
  group('Money Management Personal vs Business Separation Tests', () {
    test('MoneyTransactionModel.toJson(isPersonal: true) NEVER includes business_id', () {
      final model = MoneyTransactionModel(
        id: 'tx-123',
        userId: 'user-456',
        businessId: 'biz-789',
        transactionType: 'pay',
        personName: 'John Doe',
        phone: '1234567890',
        amount: 100.0,
        paidAmount: 20.0,
        balanceAmount: 80.0,
        dueDate: DateTime.now(),
        notes: 'Personal transaction test',
        status: 'Pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personalJson = model.toJson(isPersonal: true);
      expect(personalJson.containsKey('business_id'), isFalse);
      expect(personalJson['user_id'], equals('user-456'));

      final businessJson = model.toJson(isPersonal: false);
      expect(businessJson.containsKey('business_id'), isTrue);
      expect(businessJson['business_id'], equals('biz-789'));
    });

    test('DebtModel JSON methods respect isPersonal flag', () {
      final debt = DebtModel(
        id: 'debt-1',
        transactionId: 'tx-1',
        userId: 'user-123',
        businessId: 'biz-123',
        transactionType: 'pay',
        personName: 'Alice',
        phone: '9876543210',
        amount: 50.0,
        balanceAmount: 50.0,
        dueDate: DateTime.now(),
        notes: 'Test debt',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personalTxJson = debt.toTransactionJson(isPersonal: true);
      expect(personalTxJson.containsKey('business_id'), isFalse);
      expect(personalTxJson['user_id'], equals('user-123'));

      final businessTxJson = debt.toTransactionJson(isPersonal: false);
      expect(businessTxJson.containsKey('business_id'), isTrue);

      final personalHistJson = debt.toHistoryJson(
        parentTransactionId: 'tx-1',
        eventType: 'debt_added',
        balanceAfter: 50.0,
        isPersonal: true,
      );
      expect(personalHistJson.containsKey('business_id'), isFalse);
      expect(personalHistJson['user_id'], equals('user-123'));
    });

    test('MoneyTransactionHistoryModel.toJson(isPersonal: true) excludes business_id', () {
      final history = MoneyTransactionHistoryModel(
        id: 'h-1',
        transactionId: 'tx-1',
        userId: 'user-1',
        businessId: 'biz-1',
        eventType: 'payment',
        amount: 25.0,
        balanceAfter: 25.0,
        notes: 'Paid cash',
        createdAt: DateTime.now(),
      );

      final personalJson = history.toJson(isPersonal: true);
      expect(personalJson.containsKey('business_id'), isFalse);
      expect(personalJson['user_id'], equals('user-1'));
    });
  });
}
