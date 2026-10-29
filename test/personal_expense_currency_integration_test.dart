import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/currency/data/datasources/currency_local_datasource.dart';
import 'package:bizos/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_bloc.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_event.dart';
import 'package:bizos/features/personal_expense/domain/entities/personal_expense_entity.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_event.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_category_state.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/add_expense_dialog.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/analytics/expense_pie_chart.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/analytics/expense_summary_card.dart';
import 'package:bizos/features/personal_expense/presentation/widgets/expense_card.dart';

class _MockAuthRepo implements AuthRepository {
  UserModel user = UserModel(id: 'test-user', email: 'test@bizos.com');

  @override
  Stream<dynamic> get onAuthStateChange => const Stream.empty();

  @override
  Future<UserModel?> checkAuthStatus() async => user;

  @override
  Future<UserModel> login(String email, String password) async => user;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async => true;

  @override
  Future<UserModel> updateCurrency(String currencyCode) async {
    user = user.copyWith(currencyCode: currencyCode);
    return user;
  }

  @override
  Future<UserModel?> signInWithGoogle() async => user;

  @override
  Future<UserModel> completeGoogleRegistration({
    required String name,
    required String phone,
  }) async => user.copyWith(name: name, phone: phone);

  @override
  Future<GoogleRegistrationInfo?> getGoogleRegistrationInfo() async => null;
}

class _MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _MockAuthBloc()
    : super(
        AuthAuthenticated(UserModel(id: 'test-user', email: 'test@bizos.com')),
      ) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockCategoryBloc
    extends Bloc<PersonalExpenseCategoryEvent, PersonalExpenseCategoryState>
    implements PersonalExpenseCategoryBloc {
  _MockCategoryBloc()
    : super(const PersonalExpenseCategoryLoaded(categories: [])) {
    on<PersonalExpenseCategoryEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CurrencyRepositoryImpl currencyRepo;
  late _MockAuthRepo mockAuthRepo;
  late CurrencyBloc currencyBloc;
  late _MockAuthBloc mockAuthBloc;
  late _MockCategoryBloc mockCategoryBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CurrencyFormatter.init();
    mockAuthRepo = _MockAuthRepo();
    final localDataSource = CurrencyLocalDataSourceImpl();
    currencyRepo = CurrencyRepositoryImpl(
      localDataSource: localDataSource,
      authRepository: mockAuthRepo,
    );
    currencyBloc = CurrencyBloc(repository: currencyRepo);
    mockAuthBloc = _MockAuthBloc();
    mockCategoryBloc = _MockCategoryBloc();
  });

  tearDown(() {
    currencyBloc.close();
    mockAuthBloc.close();
    mockCategoryBloc.close();
  });

  Widget wrapWithProviders(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CurrencyBloc>.value(value: currencyBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<PersonalExpenseCategoryBloc>.value(
          value: mockCategoryBloc,
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('Personal Expenses Dynamic Currency Formatting Tests', () {
    testWidgets('ExpenseSummaryCard formats amount with active currency', (
      tester,
    ) async {
      // 1. Default INR
      CurrencyFormatter.setCurrencyCode('INR');
      await tester.pumpWidget(
        wrapWithProviders(
          const ExpenseSummaryCard(
            title: 'Total Expenses',
            value: 2450.75,
            icon: Icons.wallet,
            color: Colors.blue,
          ),
        ),
      );
      expect(find.textContaining('₹'), findsOneWidget);
      expect(find.textContaining('2,450.75'), findsOneWidget);

      // 2. Switch to USD
      CurrencyFormatter.setCurrencyCode('USD');
      await tester.pumpWidget(
        wrapWithProviders(
          const ExpenseSummaryCard(
            title: 'Total Expenses',
            value: 2450.75,
            icon: Icons.wallet,
            color: Colors.blue,
          ),
        ),
      );
      expect(find.textContaining('\$'), findsOneWidget);
      expect(find.textContaining('2,450.75'), findsOneWidget);

      // 3. Switch to AED
      CurrencyFormatter.setCurrencyCode('AED');
      await tester.pumpWidget(
        wrapWithProviders(
          const ExpenseSummaryCard(
            title: 'Total Expenses',
            value: 2450.75,
            icon: Icons.wallet,
            color: Colors.blue,
          ),
        ),
      );
      expect(find.textContaining('د.إ'), findsOneWidget);
    });

    testWidgets(
      'ExpensePieChart legend and center label format amounts with active currency',
      (tester) async {
        final analytics = <String, double>{'Food': 500.0, 'Travel': 300.0};

        // 1. Check with INR
        CurrencyFormatter.setCurrencyCode('INR');
        await tester.pumpWidget(
          wrapWithProviders(ExpensePieChart(categoryAnalytics: analytics)),
        );
        await tester.pumpAndSettle();

        // Legend values contain ₹ and percentage
        expect(find.textContaining('₹'), findsWidgets);
        expect(find.textContaining('500.00'), findsOneWidget);
        expect(find.textContaining('(62.5%)'), findsOneWidget);
        expect(find.textContaining('300.00'), findsOneWidget);
        expect(find.textContaining('(37.5%)'), findsOneWidget);
        expect(find.text('Category Breakdown'), findsOneWidget);

        // 2. Check with USD
        CurrencyFormatter.setCurrencyCode('USD');
        await tester.pumpWidget(
          wrapWithProviders(ExpensePieChart(categoryAnalytics: analytics)),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('\$'), findsWidgets);
        expect(find.textContaining('500.00'), findsOneWidget);

        // 3. Check with AED
        CurrencyFormatter.setCurrencyCode('AED');
        await tester.pumpWidget(
          wrapWithProviders(ExpensePieChart(categoryAnalytics: analytics)),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('د.إ'), findsWidgets);
      },
    );

    testWidgets('ExpenseCard formats amount with active currency', (
      tester,
    ) async {
      final expense = PersonalExpenseEntity(
        id: 'exp-1',
        ownerId: 'test-user',
        amount: 1250.0,
        category: 'Food',
        paymentMethod: 'Cash',
        description: 'Team Lunch',
        expenseDate: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // INR
      CurrencyFormatter.setCurrencyCode('INR');
      await tester.pumpWidget(
        wrapWithProviders(
          ExpenseCard(expense: expense, onEdit: () {}, onDelete: () {}),
        ),
      );
      expect(find.textContaining('₹'), findsOneWidget);
      expect(find.textContaining('1,250.00'), findsOneWidget);

      // EUR
      CurrencyFormatter.setCurrencyCode('EUR');
      await tester.pumpWidget(
        wrapWithProviders(
          ExpenseCard(expense: expense, onEdit: () {}, onDelete: () {}),
        ),
      );
      expect(find.textContaining('€'), findsOneWidget);

      // GBP
      CurrencyFormatter.setCurrencyCode('GBP');
      await tester.pumpWidget(
        wrapWithProviders(
          ExpenseCard(expense: expense, onEdit: () {}, onDelete: () {}),
        ),
      );
      expect(find.textContaining('£'), findsOneWidget);
    });

    testWidgets(
      'AddExpenseDialog shows dynamic prefix, helper text, and respects selected currency',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1. Test with INR
        await tester.runAsync(() async {
          currencyBloc.add(LoadCurrenciesEvent());
          await currencyBloc.stream.firstWhere((s) => !s.isLoading);
          currencyBloc.add(const SelectCurrencyEvent('INR'));
          await currencyBloc.stream.firstWhere(
            (s) => !s.isSaving && s.selectedCurrency?.code == 'INR',
          );
        });

        await tester.pumpWidget(
          wrapWithProviders(
            AddExpenseDialog(onSave: (_, _, _, _, _) {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('₹'), findsOneWidget);
        expect(find.text('Currency: INR (₹)'), findsOneWidget);
        expect(find.text('0.00'), findsOneWidget);

        // 2. Test switching to USD
        await tester.runAsync(() async {
          currencyBloc.add(const SelectCurrencyEvent('USD'));
          await currencyBloc.stream.firstWhere(
            (s) => !s.isSaving && s.selectedCurrency?.code == 'USD',
          );
        });
        await tester.pumpAndSettle();

        expect(find.text('\$'), findsOneWidget);
        expect(find.text('Currency: USD (\$)'), findsOneWidget);

        // 3. Test switching to AED
        await tester.runAsync(() async {
          currencyBloc.add(const SelectCurrencyEvent('AED'));
          await currencyBloc.stream.firstWhere(
            (s) => !s.isSaving && s.selectedCurrency?.code == 'AED',
          );
        });
        await tester.pumpAndSettle();

        expect(find.text('د.إ'), findsOneWidget);
        expect(find.text('Currency: AED (د.إ)'), findsOneWidget);
      },
    );

    testWidgets('AddExpenseDialog validates zero and negative amounts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.runAsync(() async {
        currencyBloc.add(LoadCurrenciesEvent());
        await currencyBloc.stream.firstWhere((s) => !s.isLoading);
        currencyBloc.add(const SelectCurrencyEvent('USD'));
        await currencyBloc.stream.firstWhere(
          (s) => !s.isSaving && s.selectedCurrency?.code == 'USD',
        );
      });

      await tester.pumpWidget(
        wrapWithProviders(
          AddExpenseDialog(onSave: (_, _, _, _, _) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 0 and trigger save
      await tester.enterText(find.byType(TextFormField).first, '0');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Amount must be greater than \$ 0'),
        findsOneWidget,
      );
    });
  });
}
