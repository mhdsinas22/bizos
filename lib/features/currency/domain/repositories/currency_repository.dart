import 'package:bizos/features/currency/domain/entities/country_entity.dart';
import 'package:bizos/features/currency/domain/entities/currency_entity.dart';

abstract class CurrencyRepository {
  /// Returns all active ISO 4217 currencies sorted alphabetically by name.
  List<CurrencyEntity> getAllCurrencies();

  /// Retrieves a currency by its 3-letter ISO code (case-insensitive).
  CurrencyEntity? getCurrencyByCode(String code);

  /// Searches currencies by name, code, symbol, or associated country.
  List<CurrencyEntity> searchCurrencies(String query);

  /// Returns all ISO 3166-1 countries sorted alphabetically by name.
  List<CountryEntity> getAllCountries();

  /// Retrieves a country by its 2-letter ISO code (case-insensitive).
  CountryEntity? getCountryByCode(String code);

  /// Searches countries by name, code, or associated currency code.
  List<CountryEntity> searchCountries(String query);

  /// Retrieves the currently selected currency code (defaults to 'INR').
  Future<String> getSelectedCurrencyCode();

  /// Persists the selected currency code for the user.
  Future<void> saveSelectedCurrencyCode(String code);
}
