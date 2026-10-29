import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/currency/data/datasources/currency_local_datasource.dart';
import 'package:bizos/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_bloc.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_event.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Currency Worldwide Coverage & LocalDataSource Tests', () {
    late CurrencyLocalDataSource localDataSource;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localDataSource = CurrencyLocalDataSourceImpl();
    });

    test(
      'Loads complete worldwide coverage (250 countries, 155 active currencies)',
      () {
        final currencies = localDataSource.getAllCurrencies();
        final countries = localDataSource.getAllCountries();

        expect(currencies.length, 155);
        expect(countries.length, 250);

        // Verify no duplicates in currencies
        final uniqueCodes = currencies.map((c) => c.code).toSet();
        expect(uniqueCodes.length, currencies.length);

        // Verify alphabetical sorting
        for (int i = 0; i < currencies.length - 1; i++) {
          expect(
            currencies[i].name.compareTo(currencies[i + 1].name),
            lessThanOrEqualTo(0),
          );
        }
      },
    );

    test('Correctly models countries with multiple currencies', () {
      // Panama has both PAB and USD
      final panama = localDataSource.getCountryByCode('PA');
      expect(panama, isNotNull);
      expect(panama!.currencyCodes, contains('USD'));
      expect(panama.currencyCodes, contains('PAB'));
    });

    test('Correctly models multiple countries sharing the same currency', () {
      final eur = localDataSource.getCurrencyByCode('EUR');
      expect(eur, isNotNull);
      expect(eur!.countryCodes.length, greaterThan(20));
      expect(eur.countryNames, contains('France'));
      expect(eur.countryNames, contains('Germany'));
    });

    test('Search by currency name, ISO code, symbol, and country name', () {
      // 1. Search by currency name
      final rupeeResults = localDataSource.searchCurrencies('Rupee');
      expect(rupeeResults.any((c) => c.code == 'INR'), isTrue);

      // 2. Search by ISO code
      final usdResults = localDataSource.searchCurrencies('USD');
      expect(usdResults.length, 1);
      expect(usdResults.first.code, 'USD');

      // 3. Search by symbol
      final euroSymbolResults = localDataSource.searchCurrencies('€');
      expect(euroSymbolResults.any((c) => c.code == 'EUR'), isTrue);

      // 4. Search by associated country name
      final japanResults = localDataSource.searchCurrencies('Japan');
      expect(japanResults.any((c) => c.code == 'JPY'), isTrue);

      final emiratesResults = localDataSource.searchCurrencies(
        'United Arab Emirates',
      );
      expect(emiratesResults.any((c) => c.code == 'AED'), isTrue);
    });

    test('Decimal precision metadata is accurate', () {
      final jpy = localDataSource.getCurrencyByCode('JPY');
      expect(jpy!.decimalDigits, 0);

      final bhd = localDataSource.getCurrencyByCode('BHD');
      expect(bhd!.decimalDigits, 3);

      final usd = localDataSource.getCurrencyByCode('USD');
      expect(usd!.decimalDigits, 2);

      final inr = localDataSource.getCurrencyByCode('INR');
      expect(inr!.decimalDigits, 2);
    });

    test('Defaults to INR when preference is empty or null', () async {
      SharedPreferences.setMockInitialValues({});
      final code = await localDataSource.getSelectedCurrencyCode();
      expect(code, 'INR');
    });

    test('Persists and retrieves selected currency code', () async {
      await localDataSource.saveSelectedCurrencyCode('AED');
      final code = await localDataSource.getSelectedCurrencyCode();
      expect(code, 'AED');
    });
  });

  group('CurrencyFormatter Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await CurrencyFormatter.init();
    });

    test('Formats default INR correctly', () {
      CurrencyFormatter.setCurrencyCode('INR');
      final formatted = CurrencyFormatter.format(1500.5);
      expect(formatted, contains('1,500.50'));
      expect(formatted, contains('₹'));
    });

    test('Formats 0 decimal currencies without cents (JPY)', () {
      CurrencyFormatter.setCurrencyCode('JPY');
      final formatted = CurrencyFormatter.format(1500);
      expect(formatted, contains('1,500'));
      expect(formatted, isNot(contains('.')));
    });

    test('Formats 3 decimal currencies correctly (BHD)', () {
      CurrencyFormatter.setCurrencyCode('BHD');
      final formatted = CurrencyFormatter.format(12.345);
      expect(formatted, contains('12.345'));
    });

    test('Formats with explicit currency code override', () {
      CurrencyFormatter.setCurrencyCode('INR');
      final formattedUsd = CurrencyFormatter.format(100, currencyCode: 'USD');
      expect(formattedUsd, contains('\$'));
      expect(formattedUsd, contains('100.00'));
    });

    test('Honors explicit decimalDigits parameter override', () {
      CurrencyFormatter.setCurrencyCode('INR');
      final formatted = CurrencyFormatter.format(100.5678, decimalDigits: 0);
      expect(formatted, isNot(contains('.')));
    });
  });

  group('CurrencyBloc & Repository Integration Tests', () {
    late CurrencyRepositoryImpl repository;
    late _MockAuthRepo mockAuthRepo;
    late CurrencyBloc bloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockAuthRepo = _MockAuthRepo();
      final localDataSource = CurrencyLocalDataSourceImpl();
      repository = CurrencyRepositoryImpl(
        localDataSource: localDataSource,
        authRepository: mockAuthRepo,
      );
      bloc = CurrencyBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test(
      'LoadCurrenciesEvent populates full dataset and active currency',
      () async {
        bloc.add(LoadCurrenciesEvent());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<dynamic>((state) => state.isLoading == true),
            predicate<dynamic>(
              (state) =>
                  state.isLoading == false &&
                  state.currencies.length == 155 &&
                  state.countries.length == 250 &&
                  state.selectedCurrency?.code == 'INR',
            ),
          ]),
        );
      },
    );

    test('SelectCurrencyEvent persists selection and updates state', () async {
      bloc.add(LoadCurrenciesEvent());
      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(const SelectCurrencyEvent('EUR'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<dynamic>((state) => state.isSaving == true),
          predicate<dynamic>(
            (state) =>
                state.isSaving == false &&
                state.selectedCurrency?.code == 'EUR' &&
                state.successMessage != null,
          ),
        ]),
      );

      expect(CurrencyFormatter.currentCurrencyCode, 'EUR');
      expect(mockAuthRepo.user.currencyCode, 'EUR');
    });
  });
}
