import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/currency/data/datasources/currency_local_datasource.dart';
import 'package:bizos/features/currency/domain/entities/country_entity.dart';
import 'package:bizos/features/currency/domain/entities/currency_entity.dart';
import 'package:bizos/features/currency/domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final CurrencyLocalDataSource localDataSource;
  final AuthRepository authRepository;

  CurrencyRepositoryImpl({
    required this.localDataSource,
    required this.authRepository,
  });

  @override
  List<CurrencyEntity> getAllCurrencies() {
    return localDataSource.getAllCurrencies();
  }

  @override
  CurrencyEntity? getCurrencyByCode(String code) {
    return localDataSource.getCurrencyByCode(code);
  }

  @override
  List<CurrencyEntity> searchCurrencies(String query) {
    return localDataSource.searchCurrencies(query);
  }

  @override
  List<CountryEntity> getAllCountries() {
    return localDataSource.getAllCountries();
  }

  @override
  CountryEntity? getCountryByCode(String code) {
    return localDataSource.getCountryByCode(code);
  }

  @override
  List<CountryEntity> searchCountries(String query) {
    return localDataSource.searchCountries(query);
  }

  @override
  Future<String> getSelectedCurrencyCode() async {
    return await localDataSource.getSelectedCurrencyCode();
  }

  @override
  Future<void> saveSelectedCurrencyCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    // 1. Save to local preferences
    await localDataSource.saveSelectedCurrencyCode(cleanCode);

    // 2. Update dynamic currency formatter immediately across the app
    final entity = getCurrencyByCode(cleanCode);
    if (entity != null) {
      CurrencyFormatter.setCurrencyEntity(entity);
    } else {
      CurrencyFormatter.setCurrencyCode(cleanCode);
    }

    // 3. Sync to Supabase user profile & local cached session if authenticated
    try {
      await authRepository.updateCurrency(cleanCode);
    } catch (e) {
      AppLogger.warning('Currency saved locally; remote sync skipped: $e');
    }
  }
}
