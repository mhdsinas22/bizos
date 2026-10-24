import 'package:bizos/core/theme/theme_bloc.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/currency/data/datasources/currency_local_datasource.dart';
import 'package:bizos/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_bloc.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_event.dart';
import 'package:bizos/features/dashboard/presentation/widgets/dashboard_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeBloc & Preference Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Fresh installation defaults strictly to ThemeMode.light', () async {
      SharedPreferences.setMockInitialValues({});
      final initialMode = await ThemeBloc.getInitialThemeMode();
      expect(initialMode, ThemeMode.light);

      final bloc = ThemeBloc();
      expect(bloc.state.themeMode, ThemeMode.light);
      expect(bloc.state.isLightMode, isTrue);
      expect(bloc.state.isDarkMode, isFalse);
    });

    test('Selecting Dark Mode persists and updates state', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = ThemeBloc();

      bloc.add(SetThemeEvent(ThemeMode.dark));
      await expectLater(
        bloc.stream,
        emits(predicate<ThemeState>((s) => s.themeMode == ThemeMode.dark)),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeBloc.prefThemeKey), 'dark');
      expect(prefs.getBool(ThemeBloc.prefIsDarkKey), isTrue);

      // Verify on subsequent app launch / restart, it restores dark mode
      final restoredMode = await ThemeBloc.getInitialThemeMode();
      expect(restoredMode, ThemeMode.dark);
    });

    test('Selecting Light Mode persists and updates state', () async {
      SharedPreferences.setMockInitialValues({
        ThemeBloc.prefThemeKey: 'dark',
        ThemeBloc.prefIsDarkKey: true,
      });

      // Confirm startup restores dark
      expect(await ThemeBloc.getInitialThemeMode(), ThemeMode.dark);

      final bloc = ThemeBloc(initialMode: ThemeMode.dark);
      expect(bloc.state.themeMode, ThemeMode.dark);

      // Now switch to Light Mode
      bloc.add(SetThemeEvent(ThemeMode.light));
      await expectLater(
        bloc.stream,
        emits(predicate<ThemeState>((s) => s.themeMode == ThemeMode.light)),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeBloc.prefThemeKey), 'light');
      expect(prefs.getBool(ThemeBloc.prefIsDarkKey), isFalse);

      // Verify subsequent launch restores light mode
      final restoredMode = await ThemeBloc.getInitialThemeMode();
      expect(restoredMode, ThemeMode.light);
    });

    test('ToggleThemeEvent toggles between light and dark', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = ThemeBloc(initialMode: ThemeMode.light);

      bloc.add(ToggleThemeEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<ThemeState>((s) => s.themeMode == ThemeMode.dark)),
      );

      bloc.add(ToggleThemeEvent());
      await expectLater(
        bloc.stream,
        emits(predicate<ThemeState>((s) => s.themeMode == ThemeMode.light)),
      );
    });
  });

  group('DashboardSettingsSheet Theme UI Tests', () {
    late CurrencyBloc currencyBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CurrencyFormatter.init();
      final currencyRepo = CurrencyRepositoryImpl(
        localDataSource: CurrencyLocalDataSourceImpl(),
        authRepository: _MockAuthRepo(),
      );
      currencyBloc = CurrencyBloc(repository: currencyRepo)
        ..add(LoadCurrenciesEvent());
    });

    tearDown(() {
      currencyBloc.close();
    });

    testWidgets(
      'Renders Theme Appearance with Light and Dark options and switches immediately',
      (tester) async {
        final themeBloc = ThemeBloc(initialMode: ThemeMode.light);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ThemeBloc>.value(value: themeBloc),
              BlocProvider<CurrencyBloc>.value(value: currencyBloc),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: DashboardSettingsSheet()),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify "Theme Appearance" is displayed
        expect(find.text('Theme Appearance'), findsOneWidget);
        expect(find.text('Light theme active (Default)'), findsOneWidget);

        // Verify Light and Dark segments exist
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);

        // Tap "Dark"
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        // ThemeBloc should now be in dark mode
        expect(themeBloc.state.themeMode, ThemeMode.dark);
        expect(find.text('Dark theme active'), findsOneWidget);

        // Tap "Light"
        await tester.tap(find.text('Light'));
        await tester.pumpAndSettle();

        // ThemeBloc should now be in light mode
        expect(themeBloc.state.themeMode, ThemeMode.light);
        expect(find.text('Light theme active (Default)'), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardSettingsSheet.show opens without overflow on small screens',
      (tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final themeBloc = ThemeBloc(initialMode: ThemeMode.light);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ThemeBloc>.value(value: themeBloc),
              BlocProvider<CurrencyBloc>.value(value: currencyBloc),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => DashboardSettingsSheet.show(ctx),
                    child: const Text('Open Settings'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Theme Appearance'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
