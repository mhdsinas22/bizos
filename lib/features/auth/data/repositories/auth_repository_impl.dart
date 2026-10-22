import 'dart:convert';
import 'dart:io';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  final ShortcutRepository shortcutRepository;
  static const String _userKey = 'logged_in_user';

  AuthRepositoryImpl({
    required this.authRemoteDataSource,
    required this.shortcutRepository,
  });

  @override
  Future<UserModel> login(String emailOrUserId, String password) async {
    if (AuthConfig.useSupabaseAuth) {
      return _loginWithSupabaseAuth(emailOrUserId, password);
    } else {
      return _loginLegacy(emailOrUserId, password);
    }
  }

  Future<UserModel> _loginWithSupabaseAuth(
    String email,
    String password,
  ) async {
    try {
      final authResponse = await authRemoteDataSource
          .signInWithEmailAndPassword(email: email, password: password);

      final authUserId = authResponse.user?.id;
      if (authUserId == null) {
        throw ServerException(
          'Authentication succeeded but user identity is missing.',
        );
      }

      // Resolve existing public.users profile using auth_user_id
      var profile = await authRemoteDataSource.getUserProfileByAuthId(
        authUserId,
      );

      // Optional fallback by email if mapped auth_user_id is not yet populated
      if (profile == null && AuthConfig.fallbackProfileByEmail) {
        profile = await authRemoteDataSource.getUserProfileByEmail(email);
      }

      if (profile == null) {
        // User authenticated in Supabase Auth, but no matching profile in public.users
        await authRemoteDataSource.signOut();
        throw UserNotFoundException(
          'Profile not found for this account. Please contact administrator.',
        );
      }

      // Account status check
      final status = profile['status']?.toString().toLowerCase();
      final isActive = profile['is_active'];
      if (status == 'inactive' || isActive == false) {
        await authRemoteDataSource.signOut();
        throw AccountInactiveException();
      }

      final userModel = UserModel.fromJson(profile);

      // Store logged-in user locally WITHOUT password
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _userKey,
        jsonEncode(userModel.toJson(includePassword: false)),
      );

      return userModel;
    } on AppAuthException {
      rethrow;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection') ||
          errorStr.contains('network')) {
        throw NetworkException();
      }
      rethrow;
    }
  }

  Future<UserModel> _loginLegacy(String userId, String password) async {
    try {
      final response = await authRemoteDataSource.getUserByUserId(userId);

      if (response == null) {
        throw UserNotFoundException();
      }

      if (response['password'] != password) {
        throw InvalidPasswordException();
      }

      final status = response['status']?.toString().toLowerCase();
      final isActive = response['is_active'];
      if (status == 'inactive' || isActive == false) {
        throw AccountInactiveException();
      }

      final userModel = UserModel.fromJson(response);

      // Store logged-in user locally WITHOUT password
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _userKey,
        jsonEncode(userModel.toJson(includePassword: false)),
      );

      return userModel;
    } on AppAuthException {
      rethrow;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection') ||
          errorStr.contains('network')) {
        throw NetworkException();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 1. Revoke the shortcut token while Supabase session is active.
      try {
        await shortcutRepository.revokeAndDeleteToken();
      } catch (e, stackTrace) {
        AppLogger.error(
          'Shortcut token revocation failed during logout: $e\n$stackTrace',
        );
      } finally {
        // 2. Always clear the local shortcut token.
        try {
          await shortcutRepository.deleteToken();
        } catch (e, stackTrace) {
          AppLogger.error(
            'Failed to delete local shortcut token: $e\n$stackTrace',
          );
        }
      }
    } finally {
      // 3. Always clear the cached user and complete logout.
      await prefs.remove(_userKey);

      try {
        await authRemoteDataSource.signOut();
      } catch (e, stackTrace) {
        AppLogger.error('Error during Supabase Auth signOut: $e\n$stackTrace');
      }
    }
  }

  @override
  Future<UserModel?> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (AuthConfig.useSupabaseAuth) {
        // Validate Supabase Auth session first
        final session = Supabase.instance.client.auth.currentSession;

        AppLogger.info('SESSION EXISTS: ${session != null}');
        AppLogger.info('SESSION EXPIRED: ${session?.isExpired}');
        if (session == null || session.isExpired) {
          // No valid session, clear cached profile and return unauthenticated
          await prefs.remove(_userKey);
          return null;
        }

        // Session is valid: verify profile and account status
        try {
          final profile = await authRemoteDataSource.getUserProfileByAuthId(
            session.user.id,
          );
          if (profile != null) {
            final status = profile['status']?.toString().toLowerCase();
            final isActive = profile['is_active'];
            if (status == 'inactive' || isActive == false) {
              await authRemoteDataSource.signOut();
              await prefs.remove(_userKey);
              return null;
            }
            final userModel = UserModel.fromJson(profile);
            await prefs.setString(
              _userKey,
              jsonEncode(userModel.toJson(includePassword: false)),
            );
            return userModel;
          } else {
            // Profile missing
            await authRemoteDataSource.signOut();
            await prefs.remove(_userKey);
            return null;
          }
        } on AppAuthException {
          rethrow;
        } catch (_) {
          // Network failure while checking profile; fall back to cached user if matching auth id
          final userJson = prefs.getString(_userKey);
          if (userJson != null) {
            try {
              final cached = UserModel.fromJson(
                jsonDecode(userJson) as Map<String, dynamic>,
              );
              if (cached.authUserId.isEmpty ||
                  cached.authUserId == session.user.id) {
                return cached;
              }
            } catch (_) {}
          }
          return null;
        }
      } else {
        // Legacy flow
        final userJson = prefs.getString(_userKey);
        if (userJson == null) return null;
        final cachedMap = jsonDecode(userJson) as Map<String, dynamic>;
        // Strip cached plaintext password if previously stored
        if (cachedMap.containsKey('password') &&
            (cachedMap['password'] as String).isNotEmpty) {
          cachedMap['password'] = '';
          await prefs.setString(_userKey, jsonEncode(cachedMap));
        }
        return UserModel.fromJson(cachedMap);
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      return await authRemoteDataSource.changePassword(
        userId,
        oldPassword,
        newPassword,
      );
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection') ||
          errorStr.contains('network')) {
        throw NetworkException();
      }
      rethrow;
    }
  }
}
