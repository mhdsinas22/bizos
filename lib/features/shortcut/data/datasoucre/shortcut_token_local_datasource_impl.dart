import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_token_local_datasource.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ShortcutTokenLocalDatasourceImpl implements ShortcutTokenLocalDatasource {
  final FlutterSecureStorage flutterSecureStorage;

  ShortcutTokenLocalDatasourceImpl({required this.flutterSecureStorage});

  static const String _tokenKey = 'voryn_shortcut_token';

  @override
  Future<void> saveToken(String token) async {
    try {
      await flutterSecureStorage.write(key: _tokenKey, value: token);
    } catch (e, stackTrace) {
      AppLogger.error('Error saving shortcut token: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await flutterSecureStorage.read(key: _tokenKey);
    } catch (e, stackTrace) {
      AppLogger.error('Error reading shortcut token: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await flutterSecureStorage.delete(key: _tokenKey);
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting shortcut token: $e');
      Error.throwWithStackTrace(e, stackTrace);
    }
  }
}
