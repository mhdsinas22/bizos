import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/shortcut/domain/usecases/get_shortcut_setup_status.dart';
import 'package:bizos/features/shortcut/domain/usecases/save_shortcut_setup_progress.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSetupRepository implements ShortcutRepository {
  ShortcutSetupEntity status = const ShortcutSetupEntity(currentStep: 1);

  @override
  Future<ShortcutSetupEntity> getShortcutSetupStatus() async => status;

  @override
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity newStatus) async {
    status = newStatus;
  }

  @override
  Future<void> resetShortcutSetupProgress() async {
    status = const ShortcutSetupEntity(currentStep: 1);
  }

  @override
  Future<QuickExpenseEntity> createQuickExpense(
    QuickExpenseEntity expense,
    String userId,
  ) async =>
      expense;

  @override
  Future<void> deleteToken() async {}

  @override
  Future<List<String>> getCategories(String userId) async => [];

  @override
  Future<List<String>> getPaymentMethods() async => [];

  @override
  Future<String?> getToken() async => null;

  @override
  Future<bool> openAppleShortcuts(String url) async => true;

  @override
  Future<bool> openIosSettings() async => true;

  @override
  Future<Map<String, dynamic>> pairShortCut({required String deviceName}) async =>
      {};

  @override
  Future<void> provisionShortcutToken({required String deviceName}) async {}

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> verifyPairingCode({required String code}) async {}
}

void main() {
  late MockSetupRepository repository;
  late GetShortcutSetupStatus getStatusUseCase;
  late SaveShortcutSetupProgress saveProgressUseCase;

  setUp(() {
    repository = MockSetupRepository();
    getStatusUseCase = GetShortcutSetupStatus(repository: repository);
    saveProgressUseCase = SaveShortcutSetupProgress(repository: repository);
  });

  group('Shortcut Setup Use Cases Tests', () {
    test('retrieves initial setup status', () async {
      final status = await getStatusUseCase();
      expect(status.currentStep, equals(1));
      expect(status.isShortcutInstalled, isFalse);
      expect(status.isBackTapConfigured, isFalse);
      expect(status.isCompleted, isFalse);
    });

    test('persists updated step and flags', () async {
      const updated = ShortcutSetupEntity(
        currentStep: 6,
        isShortcutInstalled: true,
        isBackTapConfigured: true,
        isCompleted: false,
        deviceName: 'Alex iPhone',
      );

      await saveProgressUseCase(updated);
      final retrieved = await getStatusUseCase();

      expect(retrieved.currentStep, equals(6));
      expect(retrieved.isShortcutInstalled, isTrue);
      expect(retrieved.isBackTapConfigured, isTrue);
      expect(retrieved.deviceName, equals('Alex iPhone'));
    });
  });
}
