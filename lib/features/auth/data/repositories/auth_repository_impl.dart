import 'dart:convert';
import 'dart:io';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';

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
  Stream<dynamic> get onAuthStateChange =>
      authRemoteDataSource.onAuthStateChange;

  bool _isSessionExpiredOrClose(dynamic session) {
    if (session == null) return true;
    try {
      if (session.isExpired == true) return true;
      final expiresAt = session.expiresAt;
      if (expiresAt != null && expiresAt is int) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        if (DateTime.now().add(const Duration(seconds: 60)).isAfter(expiry)) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<UserModel?> _getCachedUser(
    SharedPreferences prefs, [
    String? expectedAuthId,
  ]) async {
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      final cached = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      if (expectedAuthId == null ||
          cached.authUserId.isEmpty ||
          cached.authUserId == expectedAuthId) {
        return cached;
      }
    } catch (e) {
      AppLogger.warning('Error reading cached user: $e');
    }
    return null;
  }

  @override
  Future<UserModel?> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (AuthConfig.useSupabaseAuth) {
        var session = authRemoteDataSource.currentSession;

        AppLogger.info('CHECK AUTH STATUS - SESSION EXISTS: ${session != null}');
        AppLogger.info('CHECK AUTH STATUS - SESSION EXPIRED: ${session?.isExpired}');

        // 1. If there is no Supabase session
        if (session == null) {
          final cachedUser = await _getCachedUser(prefs);
          if (cachedUser == null) {
            return null;
          }
          // If session is null but cache exists, user is signed out
          await prefs.remove(_userKey);
          return null;
        }

        // 2. If session access token is expired or close to expiring (within 60s)
        if (_isSessionExpiredOrClose(session)) {
          AppLogger.info(
            'Supabase access token is expired or close to expiring. Refreshing session...',
          );
          try {
            final authResponse = await authRemoteDataSource.refreshSession();
            session = authResponse.session ?? authRemoteDataSource.currentSession;
            AppLogger.info(
              'Session refreshed successfully. New session isExpired: ${session?.isExpired}',
            );
          } on AuthException catch (e) {
            AppLogger.error('Session refresh failed with Supabase AuthException: ${e.message}');
            final msg = e.message.toLowerCase();
            final isPermanent = msg.contains('invalid') ||
                msg.contains('revoked') ||
                msg.contains('expired') ||
                msg.contains('grant') ||
                msg.contains('not found');
            if (isPermanent) {
              await authRemoteDataSource.signOut();
              await prefs.remove(_userKey);
              throw SessionExpiredException(
                'Your session has expired. Please log in again.',
              );
            }
            final cached = await _getCachedUser(prefs, session?.user.id);
            if (cached != null) return cached;
            throw SessionExpiredException(
              'Your session has expired. Please log in again.',
            );
          } on AppAuthException catch (e) {
            AppLogger.error('Session refresh failed with AuthException: ${e.message}');
            final msg = e.message.toLowerCase();
            final isPermanent = msg.contains('invalid') ||
                msg.contains('revoked') ||
                msg.contains('expired') ||
                msg.contains('grant') ||
                msg.contains('not found');
            if (isPermanent) {
              await authRemoteDataSource.signOut();
              await prefs.remove(_userKey);
              throw SessionExpiredException(
                'Your session has expired. Please log in again.',
              );
            }
            // Non-permanent auth error: fall back to cached user for offline/temporary resilience
            final cached = await _getCachedUser(prefs, session?.user.id);
            if (cached != null) return cached;
            throw SessionExpiredException(
              'Your session has expired. Please log in again.',
            );
          } catch (e) {
            final errStr = e.toString().toLowerCase();
            final isPermanent = errStr.contains('invalid_grant') ||
                errStr.contains('refresh token') ||
                errStr.contains('revoked') ||
                errStr.contains('session expired');
            if (isPermanent) {
              await authRemoteDataSource.signOut();
              await prefs.remove(_userKey);
              throw SessionExpiredException(
                'Your session has expired. Please log in again.',
              );
            }
            AppLogger.warning(
              'Session refresh encountered non-fatal error (e.g. offline): $e',
            );
            // Temporary network failure: DO NOT LOG OUT!
            // Fall back to cached user so user is not logged out during offline/poor network
            final cached = await _getCachedUser(prefs, session?.user.id);
            if (cached != null) {
              return cached;
            }
          }
        }

        if (session == null || _isSessionExpiredOrClose(session)) {
          final cached = await _getCachedUser(prefs, session?.user.id);
          if (cached != null) {
            return cached;
          }
          await authRemoteDataSource.signOut();
          await prefs.remove(_userKey);
          throw SessionExpiredException(
            'Your session has expired. Please log in again.',
          );
        }

        // 3. Verify user profile and account active status
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
              throw AccountInactiveException();
            }

            final userModel = UserModel.fromJson(profile);
            await prefs.setString(
              _userKey,
              jsonEncode(userModel.toJson(includePassword: false)),
            );
            return userModel;
          } else {
            // Profile missing remotely; check if local cached profile exists
            final cached = await _getCachedUser(prefs, session.user.id);
            if (cached != null) {
              return cached;
            }
            await authRemoteDataSource.signOut();
            await prefs.remove(_userKey);
            return null;
          }
        } on AppAuthException {
          rethrow;
        } catch (e) {
          AppLogger.warning(
            'Network failure while checking profile; falling back to cached user: $e',
          );
          final cached = await _getCachedUser(prefs, session.user.id);
          if (cached != null) {
            return cached;
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
    } on SessionExpiredException {
      rethrow;
    } on AppAuthException {
      rethrow;
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

  @override
  Future<UserModel> updateCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) {
      throw ServerException('No logged-in user profile found.');
    }

    final current = UserModel.fromJson(
      jsonDecode(userJson) as Map<String, dynamic>,
    );
    final code = currencyCode.trim().toUpperCase();

    // Persist to Supabase if valid user ID is present
    if (current.id.isNotEmpty) {
      try {
        await authRemoteDataSource.updateUserCurrency(
          userId: current.id,
          currencyCode: code,
        );
      } catch (e) {
        AppLogger.error('Failed to sync currency to Supabase: $e');
        // Still update locally so offline / local preference persists
      }
    }

    final updated = current.copyWith(currencyCode: code);
    await prefs.setString(
      _userKey,
      jsonEncode(updated.toJson(includePassword: false)),
    );
    return updated;
  }
}
