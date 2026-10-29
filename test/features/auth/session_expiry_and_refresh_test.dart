import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart'
    as app_auth;
import 'package:bizos/features/auth/presentation/screens/auth_onboarding_screen.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/splash/presentation/splash_screen.dart';

class FakeShortcutRepo extends Fake implements ShortcutRepository {
  @override
  Future<String?> getToken() async => 'test-token';
  @override
  Future<ShortcutSetupEntity> provisionShortcutToken({
    required String deviceName,
  }) async => const ShortcutSetupEntity();
  @override
  Future<void> revokeAndDeleteToken() async {}
}

class FakeNotificationRepo extends Fake implements NotificationRepository {
  @override
  Future<void> saveFcmToken(String userId) async {}
}

class FakeDashboardRepo extends Fake implements DashboardRepository {
  @override
  Future<DashboardData> getDashboardData(
    String? businessId,
    String? ownerId,
  ) async {
    return DashboardData(
      totalBusinesses: 0,
      totalIncome: 0.0,
      totalExpense: 0.0,
      totalProfit: 0.0,
      pendingTasks: 0,
      recentActivities: [],
      monthlySummary: {},
    );
  }
}

class FakeBusinessRepo extends Fake implements BusinessRepository {
  @override
  Future<List<BusinessModel>> getBusinesses(String ownerId) async => [];
}

class MockRemoteDataSource implements AuthRemoteDataSource {
  Session? mockSession;
  User? mockAuthUser;
  Map<String, dynamic>? mockProfile;
  bool refreshCalled = false;
  Exception? refreshException;
  AuthResponse? customRefreshResponse;

  @override
  Session? get currentSession => mockSession;

  @override
  User? get currentAuthUser => mockAuthUser;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<AuthResponse> refreshSession() async {
    refreshCalled = true;
    if (refreshException != null) throw refreshException!;
    return customRefreshResponse ??
        AuthResponse(
          session: mockSession,
          user:
              mockAuthUser ??
              const User(
                id: 'auth-uid-1',
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
    return mockProfile;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async =>
      mockProfile;

  @override
  Future<Map<String, dynamic>?> getUserByUserId(String userId) async =>
      mockProfile;

  @override
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => AuthResponse(session: mockSession, user: mockAuthUser);

  @override
  Future<void> signOut() async {
    mockSession = null;
    mockAuthUser = null;
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async =>
      UserResponse.fromJson({
        'id': 'auth-uid-1',
        'app_metadata': {},
        'user_metadata': {},
        'aud': 'authenticated',
        'created_at': '2026-01-01',
      });

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async => true;

  @override
  Future<void> updateUserCurrency({
    required String userId,
    required String currencyCode,
  }) async {}

  @override
  Future<UserModel?> signInWithGoogle() async => null;

  @override
  Future<UserModel> completeGoogleRegistration({
    required String name,
    required String phone,
  }) async => UserModel(id: 'app-user-1', name: name, phone: phone);

  @override
  Future<GoogleRegistrationInfo?> getGoogleRegistrationInfo() async => null;
}

String createJwtWithExp(int exp) {
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({'exp': exp, 'sub': 'auth-uid-1'})))
      .replaceAll('=', '');
  return '$header.$payload.fake_signature';
}

Session createExpiredSession() {
  return Session(
    accessToken: createJwtWithExp(1000),
    tokenType: 'bearer',
    expiresIn: -100,
    refreshToken: 'valid-refresh-token',
    user: const User(
      id: 'auth-uid-1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    ),
  );
}

Session createValidSession() {
  final futureExp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
  return Session(
    accessToken: createJwtWithExp(futureExp),
    tokenType: 'bearer',
    expiresIn: 3600,
    refreshToken: 'valid-refresh-token',
    user: const User(
      id: 'auth-uid-1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRemoteDataSource remoteDataSource;
  late FakeShortcutRepo shortcutRepo;
  late AuthRepositoryImpl authRepo;

  final testProfile = {
    'id': 'app-user-1',
    'auth_user_id': 'auth-uid-1',
    'email': 'owner@voryn.com',
    'name': 'Owner User',
    'role': 'owner',
    'owner_id': 'app-user-1',
    'currency_code': 'USD',
  };

  final cachedUserModel = UserModel.fromJson(testProfile);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    remoteDataSource = MockRemoteDataSource();
    shortcutRepo = FakeShortcutRepo();
    authRepo = AuthRepositoryImpl(
      authRemoteDataSource: remoteDataSource,
      shortcutRepository: shortcutRepo,
    );
  });

  group('Session Refresh & Expiration Logic in AuthRepositoryImpl', () {
    test(
      'Valid unexpired session does not trigger refresh and returns user',
      () async {
        final unexpiredSession = createValidSession();

        remoteDataSource.mockSession = unexpiredSession;
        remoteDataSource.mockAuthUser = unexpiredSession.user;
        remoteDataSource.mockProfile = testProfile;

        final user = await authRepo.checkAuthStatus();

        expect(user, isNotNull);
        expect(user!.email, 'owner@voryn.com');
        expect(remoteDataSource.refreshCalled, isFalse);
      },
    );

    test(
      'Expired access token triggers refreshSession() automatically',
      () async {
        final expiredSession = createExpiredSession();
        final newSession = createValidSession();

        remoteDataSource.mockSession = expiredSession;
        remoteDataSource.mockAuthUser = expiredSession.user;
        remoteDataSource.mockProfile = testProfile;
        remoteDataSource.customRefreshResponse = AuthResponse(
          session: newSession,
          user: newSession.user,
        );

        final user = await authRepo.checkAuthStatus();

        expect(remoteDataSource.refreshCalled, isTrue);
        expect(user, isNotNull);
        expect(user!.email, 'owner@voryn.com');

        // Verify cached in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('logged_in_user'), isTrue);
      },
    );

    test(
      'Failed refresh due to invalid grant throws SessionExpiredException and clears cache',
      () async {
        final expiredSession = createExpiredSession();

        // Seed cached user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'logged_in_user',
          jsonEncode(cachedUserModel.toJson()),
        );

        remoteDataSource.mockSession = expiredSession;
        remoteDataSource.mockAuthUser = expiredSession.user;
        remoteDataSource.refreshException = const AuthException(
          'Invalid Refresh Token: Refresh Token Not Found',
        );

        await expectLater(
          authRepo.checkAuthStatus(),
          throwsA(isA<SessionExpiredException>()),
        );

        // Verify cache was cleared
        expect(prefs.containsKey('logged_in_user'), isFalse);
      },
    );

    test(
      'Failed refresh due to offline network error preserves session using cached profile',
      () async {
        final expiredSession = createExpiredSession();

        // Seed cached user
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'logged_in_user',
          jsonEncode(cachedUserModel.toJson()),
        );

        remoteDataSource.mockSession = expiredSession;
        remoteDataSource.mockAuthUser = expiredSession.user;
        remoteDataSource.refreshException = NetworkException(
          'No internet connection',
        );

        // Should NOT throw SessionExpiredException and NOT log out the user
        final user = await authRepo.checkAuthStatus();

        expect(user, isNotNull);
        expect(user!.email, 'owner@voryn.com');
        expect(prefs.containsKey('logged_in_user'), isTrue);
      },
    );
  });

  group('AuthBloc CheckAuthStatus Session Handling', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(
        authRepo: authRepo,
        saveFcmTokenUsecase: SaveFcmToken(FakeNotificationRepo()),
        shortcutRepository: shortcutRepo,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test(
      'CheckAuthStatus emits AuthUnauthenticated with message when SessionExpiredException thrown',
      () async {
        remoteDataSource.mockSession = createExpiredSession();
        remoteDataSource.refreshException = const AuthException(
          'invalid_grant',
        );

        authBloc.add(CheckAuthStatus());

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<app_auth.AuthLoading>(),
            predicate<app_auth.AuthState>((state) {
              return state.status == app_auth.AuthStatus.unauthenticated &&
                  state.errorMessage ==
                      'Your session has expired. Please log in again.';
            }),
          ]),
        );
      },
    );
  });

  group('SplashScreen Navigation based on Session State', () {
    Widget buildSplashApp(AuthRepository repo, AuthBloc bloc) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepository>.value(value: repo),
          RepositoryProvider<DashboardRepository>(
            create: (_) => FakeDashboardRepo(),
          ),
          RepositoryProvider<BusinessRepository>(
            create: (_) => FakeBusinessRepo(),
          ),
        ],
        child: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const MaterialApp(home: SplashScreen()),
        ),
      );
    }

    testWidgets('Valid session routes to MainDashboardScreen', (tester) async {
      final unexpiredSession = createValidSession();
      remoteDataSource.mockSession = unexpiredSession;
      remoteDataSource.mockAuthUser = unexpiredSession.user;
      remoteDataSource.mockProfile = testProfile;

      final authBloc = AuthBloc(
        authRepo: authRepo,
        saveFcmTokenUsecase: SaveFcmToken(FakeNotificationRepo()),
        shortcutRepository: shortcutRepo,
      );

      await tester.pumpWidget(buildSplashApp(authRepo, authBloc));
      // Run animation to completion
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      authBloc.close();
    });

    testWidgets(
      'Expired session routes to LoginScreen with expired session snackbar message',
      (tester) async {
        remoteDataSource.mockSession = createExpiredSession();
        remoteDataSource.refreshException = const AuthException(
          'invalid_grant',
        );

        final authBloc = AuthBloc(
          authRepo: authRepo,
          saveFcmTokenUsecase: SaveFcmToken(FakeNotificationRepo()),
          shortcutRepository: shortcutRepo,
        );

        await tester.pumpWidget(buildSplashApp(authRepo, authBloc));
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          find.text('Your session has expired. Please log in again.'),
          findsOneWidget,
        );

        authBloc.close();
      },
    );

    testWidgets(
      'No session routes to AuthOnboardingScreen without error snackbar',
      (tester) async {
        remoteDataSource.mockSession = null;
        remoteDataSource.mockAuthUser = null;

        final authBloc = AuthBloc(
          authRepo: authRepo,
          saveFcmTokenUsecase: SaveFcmToken(FakeNotificationRepo()),
          shortcutRepository: shortcutRepo,
        );

        await tester.pumpWidget(buildSplashApp(authRepo, authBloc));
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpAndSettle();

        expect(find.byType(AuthOnboardingScreen), findsOneWidget);
        expect(
          find.text('Your session has expired. Please log in again.'),
          findsNothing,
        );

        authBloc.close();
      },
    );
  });
}
