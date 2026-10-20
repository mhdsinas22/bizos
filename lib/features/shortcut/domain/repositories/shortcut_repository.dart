import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';

abstract class ShortcutRepository {
  // Token and Pairing Management (Existing)
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<Map<String, dynamic>> pairShortCut({required String deviceName});
  Future<void> verifyPairingCode({required String code});

  // Setup and Onboarding Status
  Future<ShortcutSetupEntity> getShortcutSetupStatus();
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity status);
  Future<void> resetShortcutSetupProgress();

  // Quick Expense Creation & Data
  Future<QuickExpenseEntity> createQuickExpense(
    QuickExpenseEntity expense,
    String userId,
  );
  Future<List<String>> getCategories(String userId);
  Future<List<String>> getPaymentMethods();

  // Platform Integration Helpers
  Future<bool> openAppleShortcuts(String url);
  Future<bool> openIosSettings();

  /// Creates a new secure shortcut token for the
  /// currently authenticated device and saves it locally.
  Future<void> provisionShortcutToken({required String deviceName});
}
