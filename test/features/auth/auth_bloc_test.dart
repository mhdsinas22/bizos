import 'package:flutter_test/flutter_test.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';

class MockNotificationRepository implements NotificationRepository {
  String? lastSavedUserId;

  @override
  Future<void> saveFcmToken(String userId) async {
    lastSavedUserId = userId;
  }
}

class MockAuthRepository implements AuthRepository {
  String? lastLoginEmail;
  String? lastLoginPassword;
  UserModel? mockUser;
  AppAuthException? loginException;
  UserModel? mockCheckAuthUser;
  bool logoutCalled = false;
  bool changePasswordResult = true;

  @override
  Future<UserModel> login(String email, String password) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (loginException != null) {
      throw loginException!;
    }
    return mockUser ??
        UserModel(
          id: 'test-app-user-id-777', // public.users.id
          email: email,
          name: 'Owner User',
          role: 'owner',
          ownerId: 'test-app-user-id-777',
          authUserId: 'auth-user-id-999',
        );
  }

  @override
  Future<UserModel?> checkAuthStatus() async {
    return mockCheckAuthUser;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    return changePasswordResult;
  }
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockNotificationRepository mockNotificationRepo;
  late SaveFcmToken saveFcmToken;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockNotificationRepo = MockNotificationRepository();
    saveFcmToken = SaveFcmToken(mockNotificationRepo);
    authBloc = AuthBloc(
      authRepo: mockAuthRepo,
      saveFcmTokenUsecase: saveFcmToken,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Migration and Security Tests', () {
    test(
      'LoginRequested successfully authenticates and preserves public.users.id for FCM token',
      () async {
        final user = UserModel(
          id: 'public-user-uuid-123', // Business ID
          email: 'owner@voryn.com',
          name: 'Owner Alice',
          role: 'owner',
          ownerId: 'public-user-uuid-123',
          authUserId: 'supabase-auth-uuid-456', // Auth ID
        );
        mockAuthRepo.mockUser = user;

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(
          LoginRequested(email: 'owner@voryn.com', password: 'mypassword'),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(2));
        expect(states[0], isA<AuthLoading>());
        expect(states[1], isA<AuthAuthenticated>());
        final authenticated = states[1] as AuthAuthenticated;
        expect(authenticated.user.id, equals('public-user-uuid-123'));
        expect(authenticated.user.authUserId, equals('supabase-auth-uuid-456'));

        // CRITICAL CHECK: FCM token must be saved with public.users.id, NEVER auth.users.id
        expect(
          mockNotificationRepo.lastSavedUserId,
          equals('public-user-uuid-123'),
        );
      },
    );

    test(
      'LoginRequested emits AuthError with isContactOwnerRequired true on UserNotFoundException',
      () async {
        mockAuthRepo.loginException = UserNotFoundException(
          'User account not found',
        );

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(
          LoginRequested(email: 'unknown@voryn.com', password: 'password'),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(2));
        expect(states[0], isA<AuthLoading>());
        expect(states[1], isA<AuthError>());
        final error = states[1] as AuthError;
        expect(error.isContactOwnerRequired, isTrue);
      },
    );

    test(
      'LoginRequested emits AuthError with isContactOwnerRequired true on AccountInactiveException',
      () async {
        mockAuthRepo.loginException = AccountInactiveException();

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(
          LoginRequested(email: 'inactive@voryn.com', password: 'password'),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(2));
        expect(states[1], isA<AuthError>());
        final error = states[1] as AuthError;
        expect(error.isContactOwnerRequired, isTrue);
      },
    );

    test(
      'LoginRequested emits AuthError with isContactOwnerRequired false on InvalidCredentialsException',
      () async {
        mockAuthRepo.loginException = InvalidCredentialsException(
          'Invalid email or password.',
        );

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(
          LoginRequested(email: 'owner@voryn.com', password: 'wrongpassword'),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(2));
        expect(states[1], isA<AuthError>());
        final error = states[1] as AuthError;
        expect(error.isContactOwnerRequired, isFalse);
      },
    );

    test(
      'CheckAuthStatus emits AuthAuthenticated when valid session exists',
      () async {
        mockAuthRepo.mockCheckAuthUser = UserModel(
          id: 'u-persisted-1',
          email: 'saved@voryn.com',
          authUserId: 'auth-uid-1',
        );

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(CheckAuthStatus());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(1));
        expect(states[0], isA<AuthAuthenticated>());
        expect(states[0].user?.id, equals('u-persisted-1'));
      },
    );

    test(
      'CheckAuthStatus emits AuthUnauthenticated when session is missing or expired',
      () async {
        mockAuthRepo.mockCheckAuthUser = null;

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(CheckAuthStatus());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(1));
        expect(states[0], isA<AuthUnauthenticated>());
      },
    );

    test(
      'LogoutRequested executes logout and emits AuthUnauthenticated',
      () async {
        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(LogoutRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, equals(2));
        expect(states[0], isA<AuthLoading>());
        expect(states[1], isA<AuthUnauthenticated>());
        expect(mockAuthRepo.logoutCalled, isTrue);
      },
    );

    test(
      'ChangePasswordEvent changes password, logs out, and emits AuthUnauthenticated',
      () async {
        // First put user in authenticated state
        mockAuthRepo.mockCheckAuthUser = UserModel(
          id: 'user-001',
          email: 'user@voryn.com',
        );
        authBloc.add(CheckAuthStatus());
        await Future.delayed(const Duration(milliseconds: 50));

        final states = <AuthState>[];
        authBloc.stream.listen(states.add);

        authBloc.add(
          ChangePasswordEvent(
            oldPassword: 'old_pass',
            newPassword: 'new_secure_pass',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.any((s) => s is AuthUnauthenticated), isTrue);
        expect(mockAuthRepo.logoutCalled, isTrue);
      },
    );
  });
}
