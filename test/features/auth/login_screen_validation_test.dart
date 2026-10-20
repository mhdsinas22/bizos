import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';

class FakeAuthBloc extends Fake implements AuthBloc {
  final AuthState _state;
  final List<AuthEvent> events = [];

  FakeAuthBloc([AuthState? state]) : _state = state ?? AuthInitial();

  @override
  AuthState get state => _state;

  @override
  Stream<AuthState> get stream => Stream.value(_state);

  @override
  void add(AuthEvent event) {
    events.add(event);
  }

  @override
  Future<void> close() async {}
}

Widget createTestApp(Widget child, FakeAuthBloc bloc) {
  return MaterialApp(
    home: BlocProvider<AuthBloc>.value(value: bloc, child: child),
  );
}

void main() {
  tearDown(() {
    AuthConfig.setUseSupabaseAuthForTesting(null);
  });

  group('LoginScreen UI and Validation Tests', () {
    testWidgets(
      'Supabase Auth Mode: Renders Email field and email keyboard type',
      (WidgetTester tester) async {
        AuthConfig.setUseSupabaseAuthForTesting(true);
        final fakeBloc = FakeAuthBloc();

        await tester.pumpWidget(createTestApp(const LoginScreen(), fakeBloc));

        // Verify branding is intact
        expect(find.text('Voryn ERP'), findsOneWidget);
        expect(find.text('Sign In'), findsNWidgets(2));
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Enter your email'), findsOneWidget);

        final emailFieldFinder = find.byType(CustomTextField).first;
        final customTextField = tester.widget<CustomTextField>(
          emailFieldFinder,
        );
        expect(
          customTextField.keyboardType,
          equals(TextInputType.emailAddress),
        );
      },
    );

    testWidgets(
      'Supabase Auth Mode: Validates empty email and empty password',
      (WidgetTester tester) async {
        AuthConfig.setUseSupabaseAuthForTesting(true);
        final fakeBloc = FakeAuthBloc();

        await tester.pumpWidget(createTestApp(const LoginScreen(), fakeBloc));

        // Tap Sign In button with empty fields
        await tester.tap(find.byType(CustomButton));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
        expect(fakeBloc.events.isEmpty, isTrue);
      },
    );

    testWidgets('Supabase Auth Mode: Validates invalid email format', (
      WidgetTester tester,
    ) async {
      AuthConfig.setUseSupabaseAuthForTesting(true);
      final fakeBloc = FakeAuthBloc();

      await tester.pumpWidget(createTestApp(const LoginScreen(), fakeBloc));

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'invalid-email-address');
      await tester.enterText(textFields.at(1), 'password123');

      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(fakeBloc.events.isEmpty, isTrue);
    });

    testWidgets(
      'Supabase Auth Mode: Dispatches LoginRequested on valid credentials',
      (WidgetTester tester) async {
        AuthConfig.setUseSupabaseAuthForTesting(true);
        final fakeBloc = FakeAuthBloc();

        await tester.pumpWidget(createTestApp(const LoginScreen(), fakeBloc));

        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'owner@voryn.com');
        await tester.enterText(textFields.at(1), 'securepass123');

        await tester.tap(find.byType(CustomButton));
        await tester.pumpAndSettle();

        expect(fakeBloc.events.length, equals(1));
        final event = fakeBloc.events.first as LoginRequested;
        expect(event.email, equals('owner@voryn.com'));
        expect(event.password, equals('securepass123'));
      },
    );

    testWidgets(
      'Legacy Mode: Renders User ID field when useSupabaseAuth is false',
      (WidgetTester tester) async {
        AuthConfig.setUseSupabaseAuthForTesting(false);
        final fakeBloc = FakeAuthBloc();

        await tester.pumpWidget(createTestApp(const LoginScreen(), fakeBloc));

        expect(find.text('User ID'), findsOneWidget);
        expect(find.text('Enter your User ID'), findsOneWidget);

        final userIdFieldFinder = find.byType(CustomTextField).first;
        final customTextField = tester.widget<CustomTextField>(
          userIdFieldFinder,
        );
        expect(customTextField.keyboardType, equals(TextInputType.text));

        // Test empty User ID validation
        await tester.tap(find.byType(CustomButton));
        await tester.pumpAndSettle();

        expect(find.text('Please enter your User ID'), findsOneWidget);
        expect(fakeBloc.events.isEmpty, isTrue);
      },
    );
  });
}
