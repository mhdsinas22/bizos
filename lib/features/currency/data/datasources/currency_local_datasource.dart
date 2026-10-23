import 'dart:convert';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos/features/currency/domain/entities/country_entity.dart';
import 'package:bizos/features/currency/domain/entities/currency_entity.dart';

abstract class CurrencyLocalDataSource {
  List<CurrencyEntity> getAllCurrencies();
  CurrencyEntity? getCurrencyByCode(String code);
  List<CurrencyEntity> searchCurrencies(String query);

  List<CountryEntity> getAllCountries();
  CountryEntity? getCountryByCode(String code);
  List<CountryEntity> searchCountries(String query);

  Future<String> getSelectedCurrencyCode();
  Future<void> saveSelectedCurrencyCode(String code);
}

class CurrencyLocalDataSourceImpl implements CurrencyLocalDataSource {
  static const String _currencyPrefKey = 'user_preferred_currency_code';

  final List<CurrencyEntity> _currencies = [];
  final List<CountryEntity> _countries = [];
  final Map<String, CurrencyEntity> _currencyByCode = {};
  final Map<String, CountryEntity> _countryByCode = {};

  bool _initialized = false;

  CurrencyLocalDataSourceImpl() {
    _initData();
  }

  void _initData() {
    if (_initialized) return;

    // 1. Process WorldCountry dataset (ISO 3166-1)
    for (final wc in WorldCountry.list) {
      final currencyCodes = wc.currencies?.map((c) => c.code).toList() ?? [];
      final country = CountryEntity(
        code: wc.codeShort.toUpperCase(),
        codeAlpha3: wc.code.toUpperCase(),
        name: wc.name.common,
        officialName: wc.name.official,
        flagEmoji: wc.emoji,
        currencyCodes: currencyCodes,
      );
      _countries.add(country);
      _countryByCode[country.code] = country;
      _countryByCode[country.codeAlpha3] = country;
    }

    // Sort countries alphabetically by common name
    _countries.sort((a, b) => a.name.compareTo(b.name));

    // 2. Pre-index reverse mapping: Currency code -> List of associated countries
    final Map<String, List<CountryEntity>> currencyToCountries = {};
    for (final country in _countries) {
      for (final currCode in country.currencyCodes) {
        currencyToCountries.putIfAbsent(currCode, () => []).add(country);
      }
    }

    // 3. Process FiatCurrency dataset (ISO 4217)
    for (final fiat in FiatCurrency.list) {
      final code = fiat.code.toUpperCase();
      final associatedCountries = currencyToCountries[code] ?? const [];

      final rawSymbol = fiat.symbol?.trim();
      final String symbol;
      if (rawSymbol != null && rawSymbol.isNotEmpty) {
        symbol = rawSymbol;
      } else if (fiat.alternateSymbols != null &&
          fiat.alternateSymbols!.isNotEmpty) {
        symbol = fiat.alternateSymbols!.first;
      } else {
        symbol = code;
      }

      // Compute disambiguated symbol for commonly shared symbols like '$'
      final String disambiguated;
      if (symbol == '\$' && code != 'USD') {
        // e.g. CAD -> CA$, AUD -> A$, SGD -> S$, HKD -> HK$
        disambiguated = '${code.substring(0, code.length - 1)}\$';
      } else if (symbol == '\$' && code == 'USD') {
        disambiguated = 'US\$';
      } else {
        disambiguated = symbol;
      }

      // Calculate decimal precision from subunit
      final int decimalDigits;
      if (fiat.subunitToUnit <= 1) {
        decimalDigits = 0;
      } else if (fiat.subunitToUnit == 1000) {
        decimalDigits = 3;
      } else if (fiat.subunitToUnit == 10) {
        decimalDigits = 1;
      } else {
        decimalDigits = 2;
      }

      final currency = CurrencyEntity(
        code: code,
        name: fiat.name,
        symbol: symbol,
        disambiguatedSymbol: disambiguated,
        decimalDigits: decimalDigits,
        decimalMark: fiat.decimalMark,
        thousandsSeparator: fiat.thousandsSeparator,
        subunit: fiat.subunit ?? '',
        countryNames: associatedCountries.map((c) => c.name).toList(),
        countryCodes: associatedCountries.map((c) => c.code).toList(),
        countryFlags: associatedCountries.map((c) => c.flagEmoji).toList(),
      );

      _currencies.add(currency);
      _currencyByCode[code] = currency;
    }

    // Sort currencies alphabetically by currency name
    _currencies.sort((a, b) => a.name.compareTo(b.name));

    _initialized = true;
  }

  @override
  List<CurrencyEntity> getAllCurrencies() {
    return List.unmodifiable(_currencies);
  }

  @override
  CurrencyEntity? getCurrencyByCode(String code) {
    return _currencyByCode[code.trim().toUpperCase()];
  }

  @override
  List<CurrencyEntity> searchCurrencies(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getAllCurrencies();

    final parts = clean.split(RegExp(r'\s+'));
    return _currencies.where((curr) {
      final text = curr.searchableText;
      return parts.every((p) => text.contains(p));
    }).toList();
  }

  @override
  List<CountryEntity> getAllCountries() {
    return List.unmodifiable(_countries);
  }

  @override
  CountryEntity? getCountryByCode(String code) {
    return _countryByCode[code.trim().toUpperCase()];
  }

  @override
  List<CountryEntity> searchCountries(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getAllCountries();

    final parts = clean.split(RegExp(r'\s+'));
    return _countries.where((country) {
      final text = country.searchableText;
      return parts.every((p) => text.contains(p));
    }).toList();
  }

  @override
  Future<String> getSelectedCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    // 1. Check direct preference
    final saved = prefs.getString(_currencyPrefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim().toUpperCase();
    }

    // 2. Fall back to logged-in user profile's currency_code
    final userJson = prefs.getString('logged_in_user');
    if (userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        final userCurrency = map['currency_code'] ?? map['currencyCode'];
        if (userCurrency != null && userCurrency.toString().trim().isNotEmpty) {
          final code = userCurrency.toString().trim().toUpperCase();
          await prefs.setString(_currencyPrefKey, code);
          return code;
        }
      } catch (_) {}
    }

    // 3. Default to INR
    return 'INR';
  }

  @override
  Future<void> saveSelectedCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = code.trim().toUpperCase();
    await prefs.setString(_currencyPrefKey, clean);
  }
}
