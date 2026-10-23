import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/shortcut/domain/usecases/create_quick_expense.dart';
import 'package:bizos/features/shortcut/domain/usecases/get_shortcut_setup_status.dart';
import 'package:bizos/features/shortcut/domain/usecases/save_shortcut_setup_progress.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_bloc.dart';
import 'package:bizos/features/shortcut/presentation/pages/quick_add_onboarding_page.dart';
import 'package:bizos/features/shortcut/presentation/widgets/quick_expense_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  final UserModel user;
  FakeAuthRepository(this.user);

  @override
  Future<UserModel> checkAuthStatus() async => user;

  @override
  Future<UserModel> login(String email, String password) async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async =>
      true;

  @override
  Future<UserModel> updateCurrency(String currencyCode) async =>
      user.copyWith(currencyCode: currencyCode);
}


class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<void> saveFcmToken(String userId) async {}
}

class MockAuthBloc extends AuthBloc {
  final AuthState _mockState;

  MockAuthBloc(
    this._mockState, {
    required super.authRepo,
    required super.saveFcmTokenUsecase,
  });

  @override
  AuthState get state => _mockState;
}

class FakeShortcutRepository implements ShortcutRepository {
  ShortcutSetupEntity setupStatus = const ShortcutSetupEntity(
    currentStep: 1,
    isShortcutInstalled: false,
    isBackTapConfigured: false,
  );
  QuickExpenseEntity? lastCreatedExpense;

  @override
  Future<QuickExpenseEntity> createQuickExpense(
    QuickExpenseEntity expense,
    String userId,
  ) async {
    lastCreatedExpense = expense.copyWith(id: 'created-expense-99');
    return lastCreatedExpense!;
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<List<String>> getCategories(String userId) async => [
        'Food & Dining',
        'Fuel & Transport',
        'Shopping',
        'Utilities',
      ];

  @override
  Future<List<String>> getPaymentMethods() async => [
        'Cash',
        'UPI',
        'Credit Card',
      ];

  @override
  Future<ShortcutSetupEntity> getShortcutSetupStatus() async => setupStatus;

  @override
  Future<String?> getToken() async => 'mock-jwt-token';

  @override
  Future<bool> openAppleShortcuts(String url) async => true;

  @override
  Future<bool> openIosSettings() async => true;

  @override
  Future<Map<String, dynamic>> pairShortCut({required String deviceName}) async =>
      {'pairing_code': 'ABC-123'};

  @override
  Future<void> provisionShortcutToken({required String deviceName}) async {}

  @override
  Future<void> resetShortcutSetupProgress() async {
    setupStatus = const ShortcutSetupEntity(currentStep: 1);
  }

  @override
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity status) async {
    setupStatus = status;
  }

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> verifyPairingCode({required String code}) async {}
}

Widget createTestWidget({
  required ShortcutBloc shortcutBloc,
  required AuthBloc authBloc,
  int initialStep = 1,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<ShortcutBloc>.value(value: shortcutBloc),
    ],
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: QuickAddOnboardingPage(initialStep: initialStep),
    ),
  );
}

void main() {
  late FakeShortcutRepository repository;
  late ShortcutBloc shortcutBloc;
  late MockAuthBloc authBloc;

  final testUser = UserModel(
    id: 'user-123',
    email: 'test@voryn.com',
    name: 'Voryn User',
    role: 'owner',
    ownerId: 'user-123',
    authUserId: 'auth-123',
  );

  setUp(() {
    repository = FakeShortcutRepository();
    shortcutBloc = ShortcutBloc(
      shortcutRepository: repository,
      getShortcutSetupStatus: GetShortcutSetupStatus(repository: repository),
      saveShortcutSetupProgress: SaveShortcutSetupProgress(repository: repository),
      createQuickExpense: CreateQuickExpense(repository: repository),
    );
    authBloc = MockAuthBloc(
      AuthAuthenticated(testUser),
      authRepo: FakeAuthRepository(testUser),
      saveFcmTokenUsecase: SaveFcmToken(FakeNotificationRepository()),
    );
  });

  tearDown(() {
    shortcutBloc.close();
    authBloc.close();
  });

  group('QuickAddOnboardingPage Widget Tests', () {
    testWidgets('renders Screen 1 Introduction with branding, benefits, and CTA',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932)); // iPhone 16 Pro Max

      await tester.pumpWidget(
        createTestWidget(
          shortcutBloc: shortcutBloc,
          authBloc: authBloc,
          initialStep: 1,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Add'), findsOneWidget);
      expect(find.text('Add expenses in seconds without opening Voryn.'), findsOneWidget);
      expect(find.text("Let's Set Up →"), findsOneWidget);
      expect(find.text('Super fast expense entry'), findsOneWidget);
      expect(find.text('Works offline'), findsOneWidget);
      expect(find.text('Secure & private'), findsOneWidget);

      await tester.ensureVisible(find.text("Let's Set Up →"));
      await tester.tap(find.text("Let's Set Up →"));
      await tester.pumpAndSettle();

      expect(find.text('Add Voryn Shortcut to your library'), findsOneWidget);
      expect(find.text('Add to Shortcuts'), findsOneWidget);
    });

    testWidgets('renders dark mode accurately without layout overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852)); // iPhone 16

      await tester.pumpWidget(
        createTestWidget(
          shortcutBloc: shortcutBloc,
          authBloc: authBloc,
          initialStep: 1,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Add'), findsOneWidget);
      expect(find.text("Let's Set Up →"), findsOneWidget);
    });

    testWidgets('renders Step 9 "You\'re nearly set!" and triggers quick add test',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        createTestWidget(
          shortcutBloc: shortcutBloc,
          authBloc: authBloc,
          initialStep: 9,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Quick Add'), findsOneWidget);
      expect(find.text('Shortcut added to your library'), findsOneWidget);
      expect(find.text('Back Tap configured'), findsOneWidget);

      // Tap Test Quick Add to transition to Step 10
      await tester.ensureVisible(find.text('Test Quick Add'));
      await tester.tap(find.text('Test Quick Add'));
      await tester.pumpAndSettle();

      expect(find.text('Quick Add Expense'), findsWidgets);
    });

    testWidgets('renders Step 10 Quick Add popup form and submits expense',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        createTestWidget(
          shortcutBloc: shortcutBloc,
          authBloc: authBloc,
          initialStep: 10,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuickExpenseForm), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '250');
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Add Expense'));
      await tester.tap(find.text('Add Expense'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // Should transition to Step 11 Success screen
      expect(find.text('Expense Added!'), findsWidgets);
      expect(find.text('View in Voryn'), findsOneWidget);
      expect(find.text('Add Another'), findsOneWidget);
    });

    testWidgets('renders Step 12 "Use with Siri" with suggested phrases',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        createTestWidget(
          shortcutBloc: shortcutBloc,
          authBloc: authBloc,
          initialStep: 12,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Use with Siri'), findsOneWidget);
      expect(find.text('Hey Siri, add expense in Voryn'), findsOneWidget);
      expect(find.text('Hey Siri, log expense in Voryn'), findsOneWidget);
      expect(find.text('All Set!'), findsOneWidget);
    });
  });
}
