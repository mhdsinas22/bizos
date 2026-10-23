import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/core/widgets/custom_button.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/staff_login_screen.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/business/data/models/business_model.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/staff/data/models/staff_business_model.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bizos/features/staff/presentation/sheets/staff_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// --- Mocks using Fake ---
class MockNotificationRepository extends Fake
    implements NotificationRepository {
  @override
  Future<void> saveFcmToken(String userId) async {}
}

class MockShortcutRepository extends Fake implements ShortcutRepository {
  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> getToken() async => 'test-token';

  @override
  Future<ShortcutSetupEntity> provisionShortcutToken({
    required String deviceName,
  }) async {
    return const ShortcutSetupEntity();
  }

  @override
  Future<void> revokeAndDeleteToken() async {}
}

class MockAuthRepository extends Fake implements AuthRepository {
  UserModel? mockUser;
  AppAuthException? errorToThrow;

  @override
  Future<UserModel> login(String email, String password) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockUser!;
  }

  @override
  Future<UserModel?> checkAuthStatus() async => mockUser;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> changePassword(String u, String o, String n) async => true;

  @override
  Future<UserModel> updateCurrency(String c) async => mockUser!;
}

class FakeStaffRepository extends Fake implements StaffRepository {
  UserModel? createdStaff;
  String? createdOwnerId;
  List<String>? createdBusinessIds;

  @override
  Future<void> createStaff(
    UserModel staff,
    String ownerId,
    List<String> businessIds,
  ) async {
    createdStaff = staff;
    createdOwnerId = ownerId;
    createdBusinessIds = businessIds;
  }

  @override
  Future<List<UserModel>> getStaffList(String ownerId) async => [];

  @override
  Future<void> updateStaff(UserModel staff, List<String> businessIds) async {}

  @override
  Future<String?> deleteStaff(String userId) async => 'Staff User';

  @override
  Future<List<StaffBusinessModel>> getStaffBusinesses(String staffId) async =>
      [];

  @override
  Future<List<UserModel>> getStaffByBusiness(String businessId) async => [];
}

class FakeBusinessRepository extends Fake implements BusinessRepository {
  @override
  Future<List<BusinessModel>> getBusinesses(String ownerId) async => [];

  @override
  Future<void> createBusiness(BusinessModel business) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepo;
  late MockNotificationRepository mockNotifRepo;
  late MockShortcutRepository mockShortcutRepo;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockNotifRepo = MockNotificationRepository();
    mockShortcutRepo = MockShortcutRepository();
    authBloc = AuthBloc(
      authRepo: mockAuthRepo,
      saveFcmTokenUsecase: SaveFcmToken(mockNotifRepo),
      shortcutRepository: mockShortcutRepo,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('Staff Authentication Flow via Supabase Auth', () {
    test('Staff login with valid email and password loads staff permissions', () async {
      final staffUser = UserModel(
        id: 'staff-uuid-123',
        name: 'Alex Staff',
        email: 'alex@company.com',
        phone: '+1 555-0101',
        role: 'Staff',
        ownerId: 'owner-uuid-456',
        authUserId: 'supabase-auth-uuid-789',
        customPermissions: const ['view_tasks', 'add_tasks'],
      );
      mockAuthRepo.mockUser = staffUser;

      authBloc.add(
        LoginRequested(
          email: 'alex@company.com',
          password: 'SecretPassword123',
        ),
      );

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthAuthenticated>((state) {
            final u = state.user;
            return u.id == 'staff-uuid-123' &&
                u.email == 'alex@company.com' &&
                u.isStaff == true &&
                u.isOwner == false &&
                u.ownerId == 'owner-uuid-456' &&
                u.authUserId == 'supabase-auth-uuid-789' &&
                u.hasPermission('view_tasks') &&
                u.hasPermission('add_tasks') &&
                !u.hasPermission('view_accounts');
          }),
        ]),
      );
    });

    test('Inactive staff account is blocked during authentication', () async {
      mockAuthRepo.errorToThrow = AccountInactiveException();

      authBloc.add(
        LoginRequested(
          email: 'inactive@company.com',
          password: 'SecretPassword123',
        ),
      );

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>((state) {
            return state.isContactOwnerRequired == true &&
                (state.message.toLowerCase().contains('disabled') ||
                    state.message.toLowerCase().contains('inactive'));
          }),
        ]),
      );
    });

    test('Staff login fails gracefully on invalid credentials', () async {
      mockAuthRepo.errorToThrow = InvalidCredentialsException();

      authBloc.add(
        LoginRequested(
          email: 'alex@company.com',
          password: 'WrongPassword',
        ),
      );

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthError>((state) {
            return state.message.contains('Invalid');
          }),
        ]),
      );
    });
  });

  group('StaffLoginScreen Widget Tests', () {
    testWidgets('Renders Staff Workspace branding, email & password fields', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const StaffLoginScreen(),
          ),
        ),
      );

      expect(find.text('Staff Workspace'), findsOneWidget);
      expect(find.text('Staff Sign In'), findsOneWidget);
      expect(find.text('Staff Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In to Staff Portal'), findsOneWidget);
      expect(
        find.text('Business Owner? Sign In to Admin Console'),
        findsOneWidget,
      );
    });

    testWidgets('Validates empty and invalid email format on staff login', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const StaffLoginScreen(),
          ),
        ),
      );

      // Tap submit with empty inputs
      await tester.tap(find.widgetWithText(CustomButton, 'Sign In to Staff Portal'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your staff email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Enter invalid email
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'invalid-email');
      await tester.enterText(fields.at(1), '123'); // short password
      await tester.tap(find.widgetWithText(CustomButton, 'Sign In to Staff Portal'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });

  group('StaffFormSheet Creation Tests', () {
    testWidgets('Validates name, email, and 6-char password on staff creation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeStaffRepo = FakeStaffRepository();
      final staffBloc = StaffBloc(fakeStaffRepo);
      final businessBloc = BusinessBloc(FakeBusinessRepository());

      final loggedInOwner = UserModel(
        id: 'owner-uuid-001',
        name: 'Owner Boss',
        email: 'owner@bizos.local',
        role: 'Owner',
      );

      mockAuthRepo.mockUser = loggedInOwner;
      authBloc.emit(AuthAuthenticated(loggedInOwner));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<StaffBloc>.value(value: staffBloc),
              BlocProvider<BusinessBloc>.value(value: businessBloc),
              RepositoryProvider<StaffRepository>.value(value: fakeStaffRepo),
            ],
            child: Scaffold(
              body: StaffFormSheet(onSave: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Name'), findsOneWidget);
      expect(find.text('Staff Email'), findsOneWidget);
      expect(find.text('Phone Number (Optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Tap create with empty fields
      final submitButton = find.widgetWithText(CustomButton, 'Create Staff Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
      expect(find.text('Please enter staff email address'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);

      // Fill in valid details
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Alice Wonderland');
      await tester.enterText(textFields.at(1), 'alice@company.com');
      await tester.enterText(textFields.at(2), '+1 555-9988');
      await tester.enterText(textFields.at(3), 'SecurePassword123');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(fakeStaffRepo.createdStaff, isNotNull);
      expect(fakeStaffRepo.createdStaff!.name, equals('Alice Wonderland'));
      expect(fakeStaffRepo.createdStaff!.email, equals('alice@company.com'));
      expect(fakeStaffRepo.createdStaff!.phone, equals('+1 555-9988'));
      expect(fakeStaffRepo.createdStaff!.role, equals('Staff'));
      expect(fakeStaffRepo.createdStaff!.ownerId, equals('owner-uuid-001'));

      staffBloc.close();
      businessBloc.close();
    });
  });
}
