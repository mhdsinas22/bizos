import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_pair_service_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShortcutPairServiceRemoteDatasourceImpl
    implements ShortcutPairServiceRemoteDatasource {
  final SupabaseClient supabaseClient;
  ShortcutPairServiceRemoteDatasourceImpl({required this.supabaseClient});

  @override
  Future<Map<String, dynamic>> pairShortCut({
    required String deviceName,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;

      if (session == null) {
        throw Exception('Please login to Voryn first.');
      }

      final response = await supabaseClient.functions.invoke(
        'shortcut-create-pairing-code',
        body: {'device_name': deviceName},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception('Failed to create pairing code.');
      }

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid pairing-code response.');
      }

      final result = Map<String, dynamic>.from(data);

      if (result['success'] != true || result['pairing_code'] is! String) {
        throw Exception(
          result['error']?.toString() ?? 'Unable to create pairing code.',
        );
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Create-Pairing-Code-Error: $e');
      Error.throwWithStackTrace(
        Exception('Unable to create pairing code: $e'),
        stackTrace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> verifyPairingCode({required String code}) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'shortcut-verify-pairing-code',
        body: {'code': code.trim().toUpperCase()},
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid pairing verification response.');
      }

      final result = Map<String, dynamic>.from(data);

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          result['error']?.toString() ?? 'Pairing verification failed.',
        );
      }

      if (result['success'] != true ||
          result['token'] is! String ||
          (result['token'] as String).isEmpty) {
        throw Exception(
          result['error']?.toString() ?? 'Invalid token received.',
        );
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Verify-Pairing-Code-Error: $e');
      Error.throwWithStackTrace(
        Exception('Unable to verify pairing code: $e'),
        stackTrace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> provisionShortcutToken({
    required String deviceName,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;

      if (session == null || session.isExpired) {
        throw Exception('Please login to Voryn first.');
      }

      final response = await supabaseClient.functions.invoke(
        'shortcut-provision-device',
        body: {'device_name': deviceName},
      );

      final data = response.data;

      if (data is! Map) {
        throw Exception('Invalid shortcut provisioning response.');
      }

      final result = Map<String, dynamic>.from(data);

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          result['error']?.toString() ?? 'Failed to provision shortcut token.',
        );
      }

      if (result['success'] != true ||
          result['token'] is! String ||
          (result['token'] as String).isEmpty) {
        throw Exception(
          result['error']?.toString() ?? 'Invalid shortcut token received.',
        );
      }

      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Shortcut token provisioning failed: $e');

      Error.throwWithStackTrace(
        Exception('Unable to setup Siri Shortcut: $e'),
        stackTrace,
      );
    }
  }
}
