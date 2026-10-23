import 'dart:async';
import 'package:bizos/bizos_app.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'test-user-id',
    name: 'Test Owner',
    email: 'test@voryn.com',
    role: 'owner',
    currencyCode: 'USD',
  );

  group('Voryn Login -> Logout -> Re-Login Lifecycle Tests', () {
    testWidgets(
      'AppStartupFlow switches LoginScreen -> MainDashboard -> LoginScreen -> MainDashboard seamlessly',
      (tester) async {
        final mockBloc = MockStreamAuthBloc(AuthUnauthenticated());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockBloc,
              child: const AppStartupFlow(),
            ),
          ),
        );

        // 1. Splash screen animation completes (1.4s)
        expect(find.byType(SplashScreen), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1450));
        await tester.pump();

        // 2. Unauthenticated user sees LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);

        // 3. User logs in successfully
        mockBloc.emitState(AuthAuthenticated(testUser));
        await tester.pump();

        // Should transition to MainDashboardScreen
        expect(find.byType(MainDashboardScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // 4. User logs out
        mockBloc.emitState(AuthLoading());
        await tester.pump();

        // AppStartupFlow MUST NOT show SplashScreen during logout
        expect(find.byType(SplashScreen), findsNothing);

        mockBloc.emitState(AuthUnauthenticated());
        await tester.pump();

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
        await tester.pump();

        expect(find.byType(MainDashboardScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets(
      'Standalone or pushed LoginScreen navigates to MainDashboardScreen on authentication success',
      (tester) async {
        final mockBloc = MockStreamAuthBloc(AuthUnauthenticated());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: mockBloc,
              child: const LoginScreen(),
            ),
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
  });
}
