import 'package:bizos/features/shortcut/core/shortcut_error_handler.dart';
import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/shortcut/domain/usecases/create_quick_expense.dart';
import 'package:flutter_test/flutter_test.dart';

class MockShortcutRepository implements ShortcutRepository {
  QuickExpenseEntity? savedExpense;
  bool shouldThrow = false;

  @override
  Future<QuickExpenseEntity> createQuickExpense(
    QuickExpenseEntity expense,
    String userId,
  ) async {
    if (shouldThrow) {
      throw const ServerFailure('Database save failed');
    }
    savedExpense = expense.copyWith(id: 'generated-uuid-123');
    return savedExpense!;
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<List<String>> getCategories(String userId) async => ['Food', 'Fuel'];

  @override
  Future<List<String>> getPaymentMethods() async => ['Cash', 'UPI'];

  @override
  Future<ShortcutSetupEntity> getShortcutSetupStatus() async =>
      const ShortcutSetupEntity();

  @override
  Future<String?> getToken() async => 'mock-token';

  @override
  Future<bool> openAppleShortcuts(String url) async => true;

  @override
  Future<bool> openIosSettings() async => true;

  @override
  Future<Map<String, dynamic>> pairShortCut({required String deviceName}) async =>
      {'pairing_code': 'ABCDEF'};

  @override
  Future<void> provisionShortcutToken({required String deviceName}) async {}

  @override
  Future<void> resetShortcutSetupProgress() async {}

  @override
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity status) async {}

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> verifyPairingCode({required String code}) async {}
}

void main() {
  late MockShortcutRepository repository;
  late CreateQuickExpense useCase;

  setUp(() {
    repository = MockShortcutRepository();
    useCase = CreateQuickExpense(repository: repository);
  });

  group('CreateQuickExpense Use Case Tests', () {
    final validExpense = QuickExpenseEntity(
      id: '',
      ownerId: 'user-456',
      amount: 250.0,
      category: 'Food & Dining',
      paymentMethod: 'Cash',
      description: 'Coffee with team',
      expenseDate: DateTime(2026, 9, 12),
      createdAt: DateTime(2026, 9, 12),
    );

    test('successfully creates and returns saved quick expense', () async {
      final result = await useCase(expense: validExpense, userId: 'user-456');

      expect(result.id, equals('generated-uuid-123'));
      expect(result.amount, equals(250.0));
      expect(result.category, equals('Food & Dining'));
      expect(result.paymentMethod, equals('Cash'));
    });

    test('throws AuthenticationRequiredFailure if userId is empty', () async {
      expect(
        () => useCase(expense: validExpense, userId: '  '),
        throwsA(isA<AuthenticationRequiredFailure>()),
      );
    });

    test('throws InvalidAmountFailure if amount is zero or negative', () async {
      final zeroExpense = validExpense.copyWith(amount: 0.0);
      expect(
        () => useCase(expense: zeroExpense, userId: 'user-456'),
        throwsA(isA<InvalidAmountFailure>()),
      );

      final negativeExpense = validExpense.copyWith(amount: -50.0);
      expect(
        () => useCase(expense: negativeExpense, userId: 'user-456'),
        throwsA(isA<InvalidAmountFailure>()),
      );
    });

    test('throws InvalidCategoryFailure if category is empty string', () async {
      final noCategoryExpense = validExpense.copyWith(category: '   ');
      expect(
        () => useCase(expense: noCategoryExpense, userId: 'user-456'),
        throwsA(isA<InvalidCategoryFailure>()),
      );
    });

    test('propagates repository server failures', () async {
      repository.shouldThrow = true;
      expect(
        () => useCase(expense: validExpense, userId: 'user-456'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
