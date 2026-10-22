import 'package:bizos/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ShortcutRemoteDatasource {
  Future<Map<String, dynamic>> pairShortCut({required String deviceName});
  Future<Map<String, dynamic>> verifyPairingCode({required String code});
  Future<String> provisionShortcutToken({required String deviceName});
  Future<void> revokeShortcutToken({required String token});
}

class ShortcutRemoteDatasourceImpl implements ShortcutRemoteDatasource {
  final SupabaseClient supabaseClient;

  ShortcutRemoteDatasourceImpl({required this.supabaseClient});

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
      Error.throwWithStackTrace(e, stackTrace);
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
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<String> provisionShortcutToken({required String deviceName}) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw Exception('Please login to Voryn first.');
      }

      final response = await supabaseClient.functions.invoke(
        'shortcut-pair',
        body: {'device_name': deviceName},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception('Failed to provision shortcut token.');
      }

      final data = response.data;
      String? token;
      if (data is Map) {
        token =
            data['pairing_token']?.toString() ??
            data['token']?.toString() ??
            data['one_time_token']?.toString();
      } else if (data is String) {
        token = data;
      }

      if (token == null || token.trim().isEmpty) {
        throw Exception('No shortcut token returned from server.');
      }

      return token.trim();
    } catch (e, stackTrace) {
      AppLogger.error('Provision-Shortcut-Token-Error: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<void> revokeShortcutToken({required String token}) async {
    try {
      final session = supabaseClient.auth.currentSession;

      if (session == null) {
        throw Exception(
          'An authenticated session is required to revoke the shortcut token.',
        );
      }

      if (token.trim().isEmpty) {
        throw Exception('Shortcut token is empty.');
      }

      final response = await supabaseClient.functions.invoke(
        'shortcut-revoke-token',
        body: {'token': token.trim()},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          'Failed to revoke shortcut token. '
          'Status: ${response.status}',
        );
      }

      final data = response.data;

      if (data is! Map || data['success'] != true) {
        final errorMessage = data is Map ? data['error']?.toString() : null;

        throw Exception(
          errorMessage ?? 'Invalid shortcut revocation response.',
        );
      }

      AppLogger.info('Shortcut token revoked successfully.');
    } catch (e, stackTrace) {
      AppLogger.error('Revoke-Shortcut-Token-Error: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
