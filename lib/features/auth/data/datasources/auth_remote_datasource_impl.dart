import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'auth_remote_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl({required this.supabase});

  @override
  Session? get currentSession => supabase.auth.currentSession;

  @override
  User? get currentAuthUser => supabase.auth.currentUser;

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth
          .signInWithPassword(email: email.trim(), password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ServerException(
                'Server is taking too long to respond. Please try again.',
              );
            },
          );
      return response;
    } on AuthException catch (e) {
      AppLogger.error("Supabase AuthException: ${e.message}");
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') ||
          msg.contains('credential') ||
          msg.contains('grant')) {
        throw InvalidCredentialsException();
      } else if (msg.contains('email not confirmed')) {
        throw AppAuthException('Email is not confirmed.');
      }
      throw AppAuthException(e.message);
    } on AppAuthException {
      rethrow;
    } catch (e) {
      AppLogger.error("Supabase signIn error: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw NetworkException();
      } else if (errorStr.contains('timeout')) {
        throw ServerException(
          'Server is taking too long to respond. Please try again.',
        );
      }
      throw ServerException();
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfileByAuthId(
    String authUserId,
  ) async {
    try {
      Map<String, dynamic>? userMap;

      // Primary strategy: query public.users where auth_user_id matches
      try {
        final response = await supabase
            .from('users')
            .select()
            .eq('auth_user_id', authUserId)
            .maybeSingle()
            .timeout(const Duration(seconds: 15));

        if (response != null) {
          userMap = Map<String, dynamic>.from(response);
        }
      } catch (e) {
        AppLogger.warning(
          "Direct profile lookup by auth_user_id failed (check RLS): $e",
        );
      }

      // Secondary fallback strategy: RPC get_my_profile (if backend deployed security-definer helper)
      if (userMap == null) {
        try {
          final rpcResponse = await supabase
              .rpc('get_my_profile')
              .maybeSingle()
              .timeout(const Duration(seconds: 10));
          if (rpcResponse != null) {
            userMap = Map<String, dynamic>.from(rpcResponse);
          }
        } catch (_) {
          // RPC may not be present yet in backend
        }
      }

      if (userMap == null) {
        return null;
      }

      await _attachStaffPermissions(userMap);
      return userMap;
    } on AppAuthException {
      rethrow;
    } catch (e) {
      AppLogger.error("Error in getUserProfileByAuthId: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw NetworkException();
      }
      throw ServerException();
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle()
          .timeout(const Duration(seconds: 15));

      if (response == null) return null;
      final userMap = Map<String, dynamic>.from(response);
      await _attachStaffPermissions(userMap);
      return userMap;
    } catch (e) {
      AppLogger.error("Error in getUserProfileByEmail: $e");
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      AppLogger.error("Error during Supabase Auth signOut: $e");
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      AppLogger.error("Supabase updateUser error: ${e.message}");
      throw AppAuthException(e.message);
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserByUserId(String userId) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('userid', userId.trim())
          .maybeSingle()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ServerException(
                'Server is taking too long to respond. Please try again.',
              );
            },
          );

      if (response == null) {
        throw UserNotFoundException();
      }

      final userMap = Map<String, dynamic>.from(response);
      await _attachStaffPermissions(userMap);
      return userMap;
    } on AppAuthException {
      rethrow;
    } catch (e) {
      AppLogger.error("error in user id:-${e.toString()}");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection')) {
        throw NetworkException();
      } else if (errorStr.contains('timeout')) {
        throw ServerException(
          'Server is taking too long to respond. Please try again.',
        );
      }
      throw ServerException();
    }
  }

  Future<void> _attachStaffPermissions(Map<String, dynamic> userMap) async {
    try {
      AppLogger.info("user map id: ${userMap['id'].toString()}");
      final permsResponse = await supabase
          .from('staff_permissions')
          .select()
          .eq('user_id', userMap['id'])
          .timeout(const Duration(seconds: 10));

      final bizPerms = <String, List<String>>{};
      for (var row in permsResponse) {
        final bizId = row['business_id']?.toString() ?? '';
        if (bizId.isEmpty) continue;

        final perms = <String>[];
        if (row['can_view_tasks'] == true) perms.add('view_tasks');
        if (row['can_add_tasks'] == true) perms.add('add_tasks');
        if (row['can_view_accounts'] == true) perms.add('view_accounts');
        bizPerms[bizId] = perms;
      }

      final flatPerms = <String>{};
      for (var perms in bizPerms.values) {
        flatPerms.addAll(perms);
      }

      userMap['permissions'] = flatPerms.toList();
      userMap['businessPermissions'] = bizPerms;
    } catch (e) {
      AppLogger.error("staff_permissions error: ${e.toString()}");
      // If staff_permissions query fails, continue without permissions
    }
  }

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    if (AuthConfig.useSupabaseAuth) {
      final user = supabase.auth.currentUser;
      final email = user?.email;
      if (email == null || email.isEmpty) {
        throw UserNotFoundException('No active authenticated user session.');
      }

      // Re-authenticate old password securely against Supabase Auth
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: oldPassword,
        );
      } on AuthException catch (e) {
        AppLogger.error('Failed to verify old password: ${e.message}');
        throw InvalidPasswordException('Incorrect old password.');
      }

      // Update password via Supabase Auth
      await updatePassword(newPassword);
      return true;
    } else {
      // Legacy path for current production compatibility
      final response = await supabase
          .from('users')
          .select()
          .eq('userid', userId)
          .eq('password', oldPassword)
          .maybeSingle();

      if (response == null) {
        throw InvalidPasswordException('Incorrect old password.');
      }

      await supabase
          .from('users')
          .update({'password': newPassword})
          .eq('userid', userId);

      return true;
    }
  }

  @override
  Future<void> updateUserCurrency({
    required String userId,
    required String currencyCode,
  }) async {
    try {
      await supabase
          .from('users')
          .update({'currency_code': currencyCode.trim().toUpperCase()})
          .eq('id', userId);
    } catch (e) {
      AppLogger.error("Failed to update user currency: $e");
      rethrow;
    }
  }
}
