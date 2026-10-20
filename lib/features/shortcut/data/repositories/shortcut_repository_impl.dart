import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/data/datasources/shortcut_local_datasource.dart';
import 'package:bizos/features/shortcut/data/datasources/shortcut_remote_datasource.dart';
import 'package:bizos/features/shortcut/data/models/quick_expense_model.dart';
import 'package:bizos/features/shortcut/data/models/shortcut_setup_model.dart';
import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class ShortcutRepositoryImpl implements ShortcutRepository {
  final ShortcutRemoteDatasource shortcutRemoteDatasource;
  final ShortcutLocalDatasource shortcutLocalDatasource;

  ShortcutRepositoryImpl({
    required this.shortcutRemoteDatasource,
    required this.shortcutLocalDatasource,
  });

  @override
  Future<void> saveToken(String token) async {
    await shortcutLocalDatasource.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await shortcutLocalDatasource.getToken();
  }

  @override
  Future<void> deleteToken() async {
    await shortcutLocalDatasource.deleteToken();
  }

  @override
  Future<Map<String, dynamic>> pairShortCut({
    required String deviceName,
  }) async {
    final result = await shortcutRemoteDatasource.pairShortCut(
      deviceName: deviceName,
    );

    final pairingCode = result['pairing_code'];
    if (pairingCode is! String || pairingCode.isEmpty) {
      throw Exception('Invalid shortcut pairing code received.');
    }

    return result;
  }

  @override
  Future<void> verifyPairingCode({required String code}) async {
    final result = await shortcutRemoteDatasource.verifyPairingCode(code: code);

    final token = result['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('Invalid shortcut token received.');
    }

    await saveToken(token);
  }

  @override
  Future<ShortcutSetupEntity> getShortcutSetupStatus() async {
    return await shortcutLocalDatasource.getSetupStatus();
  }

  @override
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity status) async {
    final model = ShortcutSetupModel.fromEntity(status);
    await shortcutLocalDatasource.saveSetupProgress(model);
  }

  @override
  Future<void> resetShortcutSetupProgress() async {
    await shortcutLocalDatasource.resetSetupProgress();
  }

  @override
  Future<QuickExpenseEntity> createQuickExpense(
    QuickExpenseEntity expense,
    String userId,
  ) async {
    final model = QuickExpenseModel.fromEntity(expense);
    return await shortcutRemoteDatasource.createQuickExpense(model, userId);
  }

  @override
  Future<List<String>> getCategories(String userId) async {
    return await shortcutRemoteDatasource.getCategories(userId);
  }

  @override
  Future<List<String>> getPaymentMethods() async {
    return await shortcutRemoteDatasource.getPaymentMethods();
  }

  @override
  Future<bool> openAppleShortcuts(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.error('Failed to open Apple Shortcuts: $e');
      return false;
    }
  }

  @override
  Future<bool> openIosSettings() async {
    try {
      // In iOS, "app-settings:" opens app settings in iOS Settings app
      final uri = Uri.parse('app-settings:');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to open iOS Settings: $e');
      return false;
    }
  }

  @override
  Future<void> provisionShortcutToken({required String deviceName}) async {
    final token = await shortcutRemoteDatasource.provisionShortcutToken(
      deviceName: deviceName,
    );
    await saveToken(token);
  }
}
