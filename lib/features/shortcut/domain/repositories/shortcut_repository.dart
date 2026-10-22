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

  // Platform Integration Helpers
  Future<bool> openAppleShortcuts(String url);
  Future<bool> openIosSettings();

  /// Creates a new secure shortcut token for the
  /// currently authenticated device and saves it locally.
  Future<void> provisionShortcutToken({required String deviceName});
  Future<void> revokeAndDeleteToken();
}
