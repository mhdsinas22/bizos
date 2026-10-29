import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  String? lastSignInEmail;
  String? lastSignInPassword;
  bool signInThrowsInvalidCredentials = false;
  bool signInThrowsNetwork = false;
  bool signOutCalled = false;
  String? lastUpdatedPassword;

  AuthResponse? mockAuthResponse;
  Map<String, dynamic>? mockUserProfile;
  Map<String, dynamic>? mockLegacyUser;
  Session? mockSession;
  User? mockAuthUser;

  @override
  Session? get currentSession => mockSession;

  @override
  User? get currentAuthUser => mockAuthUser;

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    lastSignInEmail = email;
    lastSignInPassword = password;

    if (signInThrowsInvalidCredentials) {
      throw InvalidCredentialsException('Invalid login credentials.');
    }
    if (signInThrowsNetwork) {
      throw NetworkException();
    }
    return mockAuthResponse ??
        AuthResponse(
          session: mockSession,
          user:
              mockAuthUser ??
              const User(
                id: 'mock-auth-uid-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2026-01-01',
              ),
        );
  }

  @override
  Future<Map<String, dynamic>?> getUserProfileByAuthId(
    String authUserId,
  ) async {
    return mockUserProfile;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    return mockUserProfile;
  }

  @override
  Future<Map<String, dynamic>?> getUserByUserId(String userId) async {
    return mockLegacyUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    mockSession = null;
    mockAuthUser = null;
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    lastUpdatedPassword = newPassword;
    return UserResponse.fromJson({
      'id': 'mock-auth-uid-1',
      'app_metadata': {},
      'user_metadata': {},
      'aud': 'authenticated',
      'created_at': '2026-01-01',
    });
  }

  bool refreshSessionCalled = false;
  AuthResponse? mockRefreshResponse;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<AuthResponse> refreshSession() async {
    refreshSessionCalled = true;
    return mockRefreshResponse ??
        AuthResponse(
          session: mockSession,
          user:
              mockAuthUser ??
              const User(
                id: 'mock-auth-uid-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2026-01-01',
              ),
        );
  }

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    if (oldPassword != 'correct_old_pass') {
      throw InvalidPasswordException('Incorrect old password.');
    }
    lastUpdatedPassword = newPassword;
    return true;
  }

  @override
  Future<void> updateUserCurrency({
    required String userId,
    required String currencyCode,
  }) async {}

  UserModel? mockGoogleUserModel;
  GoogleRegistrationInfo? mockGoogleRegInfo;

  @override
  Future<UserModel?> signInWithGoogle() async {
    if (signInThrowsNetwork) throw NetworkException();
    return mockGoogleUserModel;
  }

  @override
  Future<UserModel> completeGoogleRegistration({
    required String name,
    required String phone,
  }) async {
    if (signInThrowsNetwork) throw NetworkException();
    return mockGoogleUserModel ??
        UserModel(
          id: 'google-profile-id-1',
          name: name,
          email: 'google@voryn.com',
          phone: phone,
          role: 'owner',
          authUserId: 'mock-auth-uid-1',
          currencyCode: 'INR',
        );
  }

  @override
  Future<GoogleRegistrationInfo?> getGoogleRegistrationInfo() async {
    return mockGoogleRegInfo;
  }
}

class _TestMockShortcutRepository implements ShortcutRepository {
  @override
  Future<void> deleteToken() async {}
  @override
  Future<ShortcutSetupEntity> getShortcutSetupStatus() async =>
      const ShortcutSetupEntity();
  @override
  Future<String?> getToken() async => null;
  @override
  Future<bool> openAppleShortcuts(String url) async => true;
  @override
  Future<bool> openIosSettings() async => true;
  @override
  Future<Map<String, dynamic>> pairShortCut({
    required String deviceName,
  }) async => {};
  @override
  Future<void> provisionShortcutToken({required String deviceName}) async {}
  @override
  Future<void> resetShortcutSetupProgress() async {}
  @override
  Future<void> revokeAndDeleteToken() async {}
  @override
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity status) async {}
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> verifyPairingCode({required String code}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(
      authRemoteDataSource: mockDataSource,
      shortcutRepository: _TestMockShortcutRepository(),
    );
  });

  tearDown(() {
    AuthConfig.setUseSupabaseAuthForTesting(null);
  });

  group('AuthRepositoryImpl - Supabase Auth Mode', () {
    setUp(() {
      AuthConfig.setUseSupabaseAuthForTesting(true);
    });

    test(
      'Passes correct email and password to Supabase Auth and maps profile',
      () async {
        mockDataSource.mockAuthUser = const User(
          id: 'auth-user-uuid-101',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
          email: 'owner@voryn.com',
        );
        mockDataSource.mockUserProfile = {
          'id': 'business-user-uuid-001', // Existing public.users.id
          'userid': 'owner_biz',
          'name': 'Primary Owner',
          'email': 'owner@voryn.com',
          'phone': '1234567890',
          'role': 'owner',
          'owner_id': 'business-user-uuid-001', // Preserved owner relationship
          'auth_user_id': 'auth-user-uuid-101',
          'status': 'active',
          'is_active': true,
        };

        final user = await repository.login('owner@voryn.com', 'mypassword123');

        // Verify credentials passed to datasource
        expect(mockDataSource.lastSignInEmail, equals('owner@voryn.com'));
        expect(mockDataSource.lastSignInPassword, equals('mypassword123'));

        // Verify business ID and owner ID preserved
        expect(user.id, equals('business-user-uuid-001'));
        expect(user.ownerId, equals('business-user-uuid-001'));
        expect(user.authUserId, equals('auth-user-uuid-101'));
        expect(user.role, equals('owner'));

        // Verify password excluded from local storage
        final prefs = await SharedPreferences.getInstance();
        final storedJson = prefs.getString('logged_in_user');
        expect(storedJson, isNotNull);
        final storedMap = jsonDecode(storedJson!) as Map<String, dynamic>;
        expect(storedMap.containsKey('password'), isFalse);
        expect(storedMap['id'], equals('business-user-uuid-001'));
      },
    );

    test(
      'Handles invalid credentials by throwing InvalidCredentialsException',
      () async {
        mockDataSource.signInThrowsInvalidCredentials = true;

        expect(
          () => repository.login('wrong@voryn.com', 'badpass'),
          throwsA(isA<InvalidCredentialsException>()),
        );
      },
    );

    test('Handles network failure by throwing NetworkException', () async {
      mockDataSource.signInThrowsNetwork = true;

      expect(
        () => repository.login('owner@voryn.com', 'password123'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'Missing user profile throws UserNotFoundException and signs out of Supabase Auth',
      () async {
        mockDataSource.mockAuthUser = const User(
          id: 'auth-unlinked-uid',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        );
        mockDataSource.mockUserProfile =
            null; // Profile not found in public.users

        expect(
          () => repository.login('unlinked@voryn.com', 'secret'),
          throwsA(isA<UserNotFoundException>()),
        );

        // Verify immediate security signout
        await Future.delayed(Duration.zero);
        expect(mockDataSource.signOutCalled, isTrue);
      },
    );

    test(
      'Inactive user profile throws AccountInactiveException and signs out of Supabase Auth',
      () async {
        mockDataSource.mockAuthUser = const User(
          id: 'auth-user-inactive',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-01-01',
        );
        mockDataSource.mockUserProfile = {
          'id': 'bus-inactive-01',
          'userid': 'inactive_user',
          'role': 'staff',
          'owner_id': 'bus-owner-01',
          'auth_user_id': 'auth-user-inactive',
          'status': 'inactive',
          'is_active': false,
        };

        expect(
          () => repository.login('inactive@voryn.com', 'password'),
          throwsA(isA<AccountInactiveException>()),
        );

        // Verify immediate security signout
        await Future.delayed(Duration.zero);
        expect(mockDataSource.signOutCalled, isTrue);
      },
    );

    test(
      'checkAuthStatus returns null and clears local data when session is missing or expired',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'logged_in_user',
          jsonEncode({'id': 'u1', 'name': 'Old User'}),
        );

        mockDataSource.mockSession = null; // No active session

        final status = await repository.checkAuthStatus();
        expect(status, isNull);
        expect(prefs.getString('logged_in_user'), isNull);
      },
    );

    test(
      'checkAuthStatus returns restored user when session is valid and active',
      () async {
        mockDataSource.mockSession = Session(
          accessToken: 'valid-jwt-token',
          tokenType: 'bearer',
          user: const User(
            id: 'auth-user-active',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-01-01',
          ),
        );
        mockDataSource.mockUserProfile = {
          'id': 'bus-active-01',
          'userid': 'active_owner',
          'name': 'Active Owner',
          'role': 'owner',
          'owner_id': 'bus-active-01',
          'auth_user_id': 'auth-user-active',
          'status': 'active',
          'is_active': true,
        };

        final restored = await repository.checkAuthStatus();
        expect(restored, isNotNull);
        expect(restored!.id, equals('bus-active-01'));
        expect(restored.authUserId, equals('auth-user-active'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('logged_in_user'), isNotNull);
      },
    );

    test('logout removes cached user and signs out of Supabase Auth', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_user', jsonEncode({'id': 'u1'}));

      await repository.logout();

      expect(prefs.getString('logged_in_user'), isNull);
      expect(mockDataSource.signOutCalled, isTrue);
    });

    test(
      'changePassword verifies old password and updates new password',
      () async {
        final success = await repository.changePassword(
          'u1',
          'correct_old_pass',
          'new_secure_pass_456',
        );
        expect(success, isTrue);
        expect(
          mockDataSource.lastUpdatedPassword,
          equals('new_secure_pass_456'),
        );

        expect(
          () => repository.changePassword('u1', 'wrong_old_pass', 'new_pass'),
          throwsA(isA<InvalidPasswordException>()),
        );
      },
    );
  });

  group('AuthRepositoryImpl - Legacy Mode Compatibility', () {
    setUp(() {
      AuthConfig.setUseSupabaseAuthForTesting(false);
    });

    test(
      'Legacy login authenticates via getUserByUserId and excludes password from cache',
      () async {
        mockDataSource.mockLegacyUser = {
          'id': 'legacy-uuid-001',
          'userid': 'legacy_user',
          'password': 'plain_password',
          'name': 'Legacy Owner',
          'role': 'owner',
          'owner_id': 'legacy-uuid-001',
          'status': 'active',
          'is_active': true,
        };

        final user = await repository.login('legacy_user', 'plain_password');
        expect(user.id, equals('legacy-uuid-001'));

        final prefs = await SharedPreferences.getInstance();
        final storedJson = prefs.getString('logged_in_user');
        final storedMap = jsonDecode(storedJson!) as Map<String, dynamic>;
        expect(storedMap.containsKey('password'), isFalse);
      },
    );

    test(
      'Legacy session check sanitizes stale cached password without breaking login',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'logged_in_user',
          jsonEncode({
            'id': 'legacy-uuid-001',
            'userid': 'legacy_user',
            'password': 'old_plain_password_left_in_cache',
            'name': 'Legacy Owner',
            'role': 'owner',
            'owner_id': 'legacy-uuid-001',
          }),
        );

        final user = await repository.checkAuthStatus();
        expect(user, isNotNull);
        expect(user!.id, equals('legacy-uuid-001'));

        // Check that the cached string was cleaned
        final updatedJson = prefs.getString('logged_in_user');
        final updatedMap = jsonDecode(updatedJson!) as Map<String, dynamic>;
        expect(updatedMap['password'], equals(''));
      },
    );
  });
}
