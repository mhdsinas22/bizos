import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/config/auth_config.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/core/widgets/custom_text_field.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/presentation/screens/google_registration_screen.dart';
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
        expect(find.text('Haptic'), findsOneWidget);
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

  group('GoogleRegistrationScreen UI and Validation Tests', () {
    testWidgets(
      'Prefills Full Name and read-only Email Address from GoogleRegistrationInfo',
      (WidgetTester tester) async {
        final fakeBloc = FakeAuthBloc(
          GoogleRegistrationRequired(
            authUserId: 'google-uid-123',
            email: 'newowner@gmail.com',
            suggestedName: 'Arjun Sharma',
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            const GoogleRegistrationScreen(
              registrationInfo: GoogleRegistrationInfo(
                authUserId: 'google-uid-123',
                email: 'newowner@gmail.com',
                suggestedName: 'Arjun Sharma',
              ),
            ),
            fakeBloc,
          ),
        );

        expect(find.text('Complete Registration'), findsNWidgets(2));
        expect(find.text('Arjun Sharma'), findsOneWidget);
        expect(find.text('newowner@gmail.com'), findsOneWidget);

        final customFields = tester
            .widgetList<CustomTextField>(find.byType(CustomTextField))
            .toList();
        expect(customFields[0].readOnly, isFalse);
        expect(customFields[1].readOnly, isTrue);
        expect(customFields[2].readOnly, isFalse);
      },
    );

    testWidgets(
      'Validates empty Full Name, invalid Phone Number, and dispatches CompleteGoogleRegistrationRequested on valid input',
      (WidgetTester tester) async {
        final fakeBloc = FakeAuthBloc(
          GoogleRegistrationRequired(
            authUserId: 'google-uid-123',
            email: 'newowner@gmail.com',
            suggestedName: '',
          ),
        );

        await tester.pumpWidget(
          createTestApp(
            const GoogleRegistrationScreen(
              registrationInfo: GoogleRegistrationInfo(
                authUserId: 'google-uid-123',
                email: 'newowner@gmail.com',
                suggestedName: '',
              ),
            ),
            fakeBloc,
          ),
        );

        // Tap Complete Registration with empty name and phone
        final submitButton = find.byType(CustomButton);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Please enter your full name'), findsOneWidget);
        expect(find.text('Please enter your phone number'), findsOneWidget);
        expect(fakeBloc.events.isEmpty, isTrue);

        // Enter valid name and invalid short phone
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'Arjun Sharma');
        await tester.enterText(textFields.at(2), '12345');

        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(
          find.text('Phone number must be between 7 and 15 digits'),
          findsOneWidget,
        );
        expect(fakeBloc.events.isEmpty, isTrue);

        // Enter valid phone and submit
        await tester.enterText(textFields.at(2), '+91 9876543210');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeBloc.events.length, equals(1));
        final event =
            fakeBloc.events.first as CompleteGoogleRegistrationRequested;
        expect(event.name, equals('Arjun Sharma'));
        expect(event.phone, equals('+91 9876543210'));
      },
    );
  });
}
