import 'dart:async';
import 'package:bizos/bizos_app.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasource.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:bizos/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockStreamAuthBloc extends Fake implements AuthBloc {
  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();
  AuthState _state;

  MockStreamAuthBloc([AuthState? initialState])
      : _state = initialState ?? AuthInitial();

  void emitState(AuthState state) {
    _state = state;
    _controller.add(state);
  }

  @override
  AuthState get state => _state;

  @override
  Stream<AuthState> get stream => _controller.stream;

  @override
  void add(AuthEvent event) {}

  @override
  Future<void> close() async {
    await _controller.close();
  }
}

class FakeDashboardRepository extends Fake implements DashboardRepository {
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

class FakeBusinessRepository extends Fake implements BusinessRepository {
  @override
  Future<List<BusinessModel>> getBusinesses(String ownerId) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'test-user-id',
    name: 'Test Owner',
    email: 'test@voryn.com',
    role: 'owner',
    currencyCode: 'USD',
  );

  Widget createTestApp({
    required MockStreamAuthBloc authBloc,
    required Widget child,
  }) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DashboardRepository>.value(
            value: FakeDashboardRepository(),
          ),
          RepositoryProvider<BusinessRepository>.value(
            value: FakeBusinessRepository(),
          ),
        ],
        child: MaterialApp(home: child),
      ),
    );
  }

  group('Voryn Login -> Logout -> Re-Login Lifecycle Tests', () {
    testWidgets(
      'AppStartupFlow switches LoginScreen -> MainDashboard -> LoginScreen -> MainDashboard seamlessly',
      (tester) async {
        final mockBloc = MockStreamAuthBloc(AuthUnauthenticated());

        await tester.pumpWidget(
          createTestApp(
            authBloc: mockBloc,
            child: const AppStartupFlow(),
          ),
        );

        // 1. Splash screen animation completes (1.4s)
        expect(find.byType(SplashScreen), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1450));
        // Route transition (350ms)
        await tester.pump(const Duration(milliseconds: 400));

        // 2. Unauthenticated user sees LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);

        // 3. User logs in successfully
        mockBloc.emitState(AuthAuthenticated(testUser));
        await tester.pumpAndSettle();

        // Should transition to MainDashboardScreen
        expect(find.byType(MainDashboardScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // 4. User logs out
        mockBloc.emitState(AuthLoading());
        await tester.pump();

        // AppStartupFlow MUST NOT show SplashScreen during logout
        expect(find.byType(SplashScreen), findsNothing);

        mockBloc.emitState(AuthUnauthenticated());
        await tester.pumpAndSettle();

        // User is back on LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(MainDashboardScreen), findsNothing);

        // 5. User enters credentials and logs in again
        mockBloc.emitState(AuthLoading());
        await tester.pump();

        // Must still show LoginScreen with loading state, not splash
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);

        // 6. Login succeeds: transitions immediately to MainDashboardScreen
        mockBloc.emitState(AuthAuthenticated(testUser));
        await tester.pumpAndSettle();

        expect(find.byType(MainDashboardScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets(
      'Standalone or pushed LoginScreen navigates to MainDashboardScreen on authentication success',
      (tester) async {
        final mockBloc = MockStreamAuthBloc(AuthUnauthenticated());

        await tester.pumpWidget(
          createTestApp(
            authBloc: mockBloc,
            child: const LoginScreen(),
          ),
        );

        expect(find.byType(LoginScreen), findsOneWidget);

        // Trigger login success on a standalone LoginScreen
        mockBloc.emitState(AuthAuthenticated(testUser));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Pushed/standalone LoginScreen navigates to MainDashboardScreen
        expect(find.byType(MainDashboardScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Duplicate logout events only push LoginScreen once without multiple screens on stack',
      (tester) async {
        final mockBloc = MockStreamAuthBloc(AuthAuthenticated(testUser));

        await tester.pumpWidget(
          createTestApp(
            authBloc: mockBloc,
            child: const MainDashboardScreen(),
          ),
        );

        expect(find.byType(MainDashboardScreen), findsOneWidget);

        // Simulate rapid duplicate logout emissions (stream signedOut + user event)
        mockBloc.emitState(AuthLoading());
        await tester.pump();

        mockBloc.emitState(AuthUnauthenticated());
        await tester.pump();

        // Emit unauthenticated again immediately
        mockBloc.emitState(AuthUnauthenticated());
        await tester.pumpAndSettle();

        // Exactly ONE LoginScreen must exist in the widget tree
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(MainDashboardScreen), findsNothing);
      },
    );
  });
}
