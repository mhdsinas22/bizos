import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/core/shortcut_constants.dart';
import 'package:bizos/features/shortcut/data/models/shortcut_setup_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ShortcutLocalDatasource {
  Future<ShortcutSetupModel> getSetupStatus();
  Future<void> saveSetupProgress(ShortcutSetupModel status);
  Future<void> resetSetupProgress();

  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class ShortcutLocalDatasourceImpl implements ShortcutLocalDatasource {
  final FlutterSecureStorage flutterSecureStorage;
  final SharedPreferences? sharedPreferences;

  ShortcutLocalDatasourceImpl({
    required this.flutterSecureStorage,
    this.sharedPreferences,
  });

  Future<SharedPreferences> _getPrefs() async {
    return sharedPreferences ?? await SharedPreferences.getInstance();
  }

  @override
  Future<ShortcutSetupModel> getSetupStatus() async {
    try {
      final prefs = await _getPrefs();
      final currentStep = prefs.getInt(ShortcutConstants.prefKeySetupStep) ?? 1;
      final isInstalled = prefs.getBool(ShortcutConstants.prefKeyShortcutInstalled) ?? false;
      final isBackTap = prefs.getBool(ShortcutConstants.prefKeyBackTapConfigured) ?? false;
      final isCompleted = prefs.getBool(ShortcutConstants.prefKeySetupCompleted) ?? false;
      final deviceName = prefs.getString(ShortcutConstants.prefKeyDeviceName) ?? 'iPhone';

      return ShortcutSetupModel(
        currentStep: currentStep,
        isShortcutInstalled: isInstalled,
        isBackTapConfigured: isBackTap,
        isCompleted: isCompleted,
        deviceName: deviceName,
      );
    } catch (e) {
      AppLogger.error('Error loading shortcut setup status: $e');
      return const ShortcutSetupModel();
    }
  }

  @override
  Future<void> saveSetupProgress(ShortcutSetupModel status) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(ShortcutConstants.prefKeySetupStep, status.currentStep);
      await prefs.setBool(ShortcutConstants.prefKeyShortcutInstalled, status.isShortcutInstalled);
      await prefs.setBool(ShortcutConstants.prefKeyBackTapConfigured, status.isBackTapConfigured);
      await prefs.setBool(ShortcutConstants.prefKeySetupCompleted, status.isCompleted);
      await prefs.setString(ShortcutConstants.prefKeyDeviceName, status.deviceName);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving shortcut setup progress: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<void> resetSetupProgress() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(ShortcutConstants.prefKeySetupStep);
      await prefs.remove(ShortcutConstants.prefKeyShortcutInstalled);
      await prefs.remove(ShortcutConstants.prefKeyBackTapConfigured);
      await prefs.remove(ShortcutConstants.prefKeySetupCompleted);
      await prefs.remove(ShortcutConstants.prefKeyDeviceName);
    } catch (e, stackTrace) {
      AppLogger.error('Error resetting shortcut setup progress: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await flutterSecureStorage.write(
        key: ShortcutConstants.keychainTokenKey,
        value: token,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error saving shortcut token: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await flutterSecureStorage.read(
        key: ShortcutConstants.keychainTokenKey,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error reading shortcut token: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await flutterSecureStorage.delete(
        key: ShortcutConstants.keychainTokenKey,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting shortcut token: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
