import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        AppLogger.warning("Direct profile lookup by auth_user_id failed: $e");
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('socketexception') ||
            errStr.contains('clientexception') ||
            errStr.contains('failed host lookup') ||
            errStr.contains('network') ||
            errStr.contains('connection') ||
            errStr.contains('timeout')) {
          rethrow;
        }
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
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('socketexception') ||
              errStr.contains('clientexception') ||
              errStr.contains('failed host lookup') ||
              errStr.contains('network') ||
              errStr.contains('connection') ||
              errStr.contains('timeout')) {
            rethrow;
          }
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
          errorStr.contains('connection') ||
          errorStr.contains('timeout')) {
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
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      AppLogger.warning("Error during GoogleSignIn signOut: $e");
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

  @override
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await supabase.auth.refreshSession();
      AppLogger.info("Supabase session refreshed successfully.");
      return response;
    } on AuthException catch (e) {
      AppLogger.error("Supabase refreshSession AuthException: ${e.message}");
      throw AppAuthException(e.message);
    } catch (e) {
      AppLogger.error("Supabase refreshSession error: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('timeout')) {
        throw NetworkException();
      }
      throw ServerException();
    }
  }

  static const String _googleIosClientId =
      '705481714469-ao2fjp32ujennto742s80f9lnncq6bsa.apps.googleusercontent.com';

  static const String _googleWebClientId =
      '705481714469-0vao0o2fj97jcj407fqhi01n9oam5pb9.apps.googleusercontent.com';
  static bool _googleInitialized = false;
  Future<void> _initalizeGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _googleIosClientId,
      serverClientId: _googleWebClientId,
    );
    _googleInitialized = true;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      await _initalizeGoogleSignIn();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final String? idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AppAuthException(
          'Google authentication failed: missing ID token. Please try again.',
        );
      }

      final authResponse = await supabase.auth
          .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ServerException(
                'Server is taking too long to respond. Please try again.',
              );
            },
          );

      final authUser = authResponse.user ?? supabase.auth.currentUser;
      final session = authResponse.session ?? supabase.auth.currentSession;
      if (authUser == null || session == null || authUser.id.isEmpty) {
        throw AppAuthException(
          'Supabase authentication session could not be established. Please try again.',
        );
      }

      final email = authUser.email?.trim() ?? '';
      if (email.isEmpty) {
        await signOut();
        throw AppAuthException(
          'Google account email is unavailable. Please use an account with a valid email.',
        );
      }

      final profile = await getUserProfileByAuthId(authUser.id);
      if (profile == null) {
        return null;
      }

      final status = profile['status']?.toString().toLowerCase();
      final isActive = profile['is_active'];
      if (status == 'inactive' || isActive == false) {
        await signOut();
        throw AccountInactiveException();
      }

      return UserModel.fromJson(profile);
    } on GoogleSignInException catch (e) {
      AppLogger.warning('GoogleSignInException (${e.code}): ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw GoogleSignInCancelledException();
      }
      final desc = (e.description ?? '').toLowerCase();
      if (desc.contains('network') || desc.contains('connection')) {
        throw NetworkException();
      }
      throw AppAuthException(
        'Google sign-in could not be completed. Please try again.',
      );
    } on AuthException catch (e) {
      AppLogger.error('Supabase Google AuthException: ${e.message}');
      throw AppAuthException(
        e.message.isNotEmpty
            ? e.message
            : 'Authentication with Google failed. Please try again.',
      );
    } on AppAuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error during signInWithGoogle: $e');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        throw GoogleSignInCancelledException();
      }
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
      throw ServerException(
        'Unable to sign in with Google right now. Please try again.',
      );
    }
  }

  @override
  Future<UserModel> completeGoogleRegistration({
    required String name,
    required String phone,
  }) async {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    if (trimmedName.isEmpty) {
      throw AppAuthException('Please enter your full name.');
    }
    if (trimmedPhone.isEmpty) {
      throw AppAuthException('Please enter your phone number.');
    }

    var session = supabase.auth.currentSession;
    var authUser = supabase.auth.currentUser;

    if (session == null || authUser == null || authUser.id.isEmpty) {
      throw SessionExpiredException(
        'Your Google session has expired. Please sign in again.',
      );
    }

    if (session.user.id != authUser.id) {
      await signOut();
      throw SessionExpiredException(
        'Invalid authentication session. Please sign in again.',
      );
    }

    if (session.isExpired) {
      try {
        final refreshed = await refreshSession();
        session = refreshed.session ?? supabase.auth.currentSession;
        authUser = refreshed.user ?? supabase.auth.currentUser;
      } catch (_) {
        await signOut();
        throw SessionExpiredException(
          'Your Google session has expired. Please sign in again.',
        );
      }
      if (session == null || authUser == null) {
        throw SessionExpiredException(
          'Your Google session has expired. Please sign in again.',
        );
      }
    }

    final verifiedAuthUserId = session.user.id;
    final email = authUser.email?.trim() ?? '';
    if (email.isEmpty) {
      throw AppAuthException(
        'Google account email is unavailable. Please sign in again.',
      );
    }

    try {
      final existingProfile = await getUserProfileByAuthId(verifiedAuthUserId);
      if (existingProfile != null) {
        final status = existingProfile['status']?.toString().toLowerCase();
        final isActive = existingProfile['is_active'];
        if (status == 'inactive' || isActive == false) {
          await signOut();
          throw AccountInactiveException();
        }
        return UserModel.fromJson(existingProfile);
      }

      final response = await supabase
          .from('users')
          .insert({
            'name': trimmedName,
            'email': email,
            'phone': trimmedPhone,
            'auth_user_id': verifiedAuthUserId,
            'role': 'owner',
            'currency_code': 'INR',
          })
          .select()
          .single()
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ServerException(
                'Server is taking too long to respond. Please try again.',
              );
            },
          );

      final profile = Map<String, dynamic>.from(response);
      await _attachStaffPermissions(profile);
      return UserModel.fromJson(profile);
    } on PostgrestException catch (e) {
      AppLogger.error(
        'PostgrestException in completeGoogleRegistration (${e.code}): ${e.message}',
      );
      if (e.code == '23505') {
        final existing = await getUserProfileByAuthId(verifiedAuthUserId);
        if (existing != null) {
          return UserModel.fromJson(existing);
        }
        throw DuplicateRegistrationException(
          'An account with these details already exists. Please sign in instead.',
        );
      }
      if (e.code == '42501') {
        throw AppAuthException(
          'Permission denied while creating your profile. Please try signing in again.',
        );
      }
      throw ServerException(
        'Could not create your profile right now. Please try again.',
      );
    } on AppAuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error in completeGoogleRegistration: $e');
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
      throw ServerException(
        'Failed to complete registration. Please try again.',
      );
    }
  }

  @override
  Future<GoogleRegistrationInfo?> getGoogleRegistrationInfo() async {
    final session = supabase.auth.currentSession;
    final user = supabase.auth.currentUser;

    if (session == null || user == null || session.user.id != user.id) {
      return null;
    }

    final metadata = user.userMetadata ?? {};

    final fullName = (metadata['full_name'] as String?)?.trim() ?? '';
    final name = (metadata['name'] as String?)?.trim() ?? '';
    final suggestedName = fullName.isNotEmpty ? fullName : name;

    return GoogleRegistrationInfo(
      authUserId: user.id,
      email: (user.email ?? '').trim(),
      suggestedName: suggestedName,
    );
  }

  @override
  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;
}
