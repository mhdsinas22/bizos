import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sealed_countries/sealed_countries.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos/features/currency/domain/entities/currency_entity.dart';

class CurrencyFormatter {
  static const String _prefKey = 'user_preferred_currency_code';

  static String _currentCurrencyCode = 'INR';
  static CurrencyEntity? _currentCurrency;

  /// Returns the currently active currency code (default 'INR').
  static String get currentCurrencyCode => _currentCurrencyCode;

  /// Returns the currently active CurrencyEntity.
  static CurrencyEntity? get currentCurrency => _currentCurrency;

  /// Returns the active currency symbol (e.g. '₹', '$', '€').
  static String get currencySymbol {
    if (_currentCurrency != null) {
      return _currentCurrency!.symbol;
    }
    return '₹';
  }

  /// Initializes the currency formatter from SharedPreferences / cached user.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? code = prefs.getString(_prefKey);

      if (code == null || code.trim().isEmpty) {
        final userJson = prefs.getString('logged_in_user');
        if (userJson != null) {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          final userCurrency = map['currency_code'] ?? map['currencyCode'];
          if (userCurrency != null &&
              userCurrency.toString().trim().isNotEmpty) {
            code = userCurrency.toString().trim().toUpperCase();
          }
        }
      }

      setCurrencyCode(code ?? 'INR');
    } catch (_) {
      setCurrencyCode('INR');
    }
  }

  /// Sets the active currency from an entity.
  static void setCurrencyEntity(CurrencyEntity entity) {
    _currentCurrency = entity;
    _currentCurrencyCode = entity.code.toUpperCase();
  }

  /// Sets the active currency from a 3-letter ISO 4217 code.
  static void setCurrencyCode(String code) {
    final clean = code.trim().toUpperCase();
    _currentCurrencyCode = clean.isNotEmpty ? clean : 'INR';

    final fiat = FiatCurrency.maybeFromCode(_currentCurrencyCode);
    if (fiat != null) {
      final rawSymbol = fiat.symbol?.trim();
      final String symbol;
      if (rawSymbol != null && rawSymbol.isNotEmpty) {
        symbol = rawSymbol;
      } else if (fiat.alternateSymbols != null &&
          fiat.alternateSymbols!.isNotEmpty) {
        symbol = fiat.alternateSymbols!.first;
      } else {
        symbol = fiat.code;
      }

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

      _currentCurrency = CurrencyEntity(
        code: fiat.code,
        name: fiat.name,
        symbol: symbol,
        disambiguatedSymbol: symbol == '\$' && fiat.code != 'USD'
            ? '${fiat.code.substring(0, fiat.code.length - 1)}\$'
            : (symbol == '\$' && fiat.code == 'USD' ? 'US\$' : symbol),
        decimalDigits: decimalDigits,
        decimalMark: fiat.decimalMark,
        thousandsSeparator: fiat.thousandsSeparator,
        subunit: fiat.subunit ?? '',
      );
    }
  }

  /// Backwards-compatible alias for setCurrencyCode
  static void setCurrency(String code) => setCurrencyCode(code);

  /// Formats the given [amount] with currency symbol, grouping, and decimal precision.
  ///
  /// - [amount]: The numerical value to format.
  /// - [currencyCode]: Optional ISO 4217 code override. Defaults to active user currency.
  /// - [decimalDigits]: Optional explicit decimal precision override. Defaults to currency standard.
  /// - [showCode]: If true, appends or prepends ISO code (e.g. '$100.00 USD').
  static String format(
    num amount, {
    String? currencyCode,
    int? decimalDigits,
    bool showCode = false,
  }) {
    final code = (currencyCode != null && currencyCode.trim().isNotEmpty)
        ? currencyCode.trim().toUpperCase()
        : _currentCurrencyCode;

    CurrencyEntity? entity = (code == _currentCurrencyCode)
        ? _currentCurrency
        : null;

    if (entity == null) {
      final fiat = FiatCurrency.maybeFromCode(code);
      if (fiat != null) {
        final rawSymbol = fiat.symbol?.trim();
        final symbol = (rawSymbol != null && rawSymbol.isNotEmpty)
            ? rawSymbol
            : (fiat.alternateSymbols != null &&
                      fiat.alternateSymbols!.isNotEmpty
                  ? fiat.alternateSymbols!.first
                  : fiat.code);
        final digits = fiat.subunitToUnit <= 1
            ? 0
            : (fiat.subunitToUnit == 1000 ? 3 : 2);
        entity = CurrencyEntity(
          code: fiat.code,
          name: fiat.name,
          symbol: symbol,
          disambiguatedSymbol: symbol,
          decimalDigits: digits,
        );
      }
    }

    final String symbol = entity?.symbol ?? (code == 'INR' ? '₹' : code);
    final int digits = decimalDigits ?? entity?.decimalDigits ?? 2;

    try {
      final formatter = NumberFormat.currency(
        name: code,
        symbol: symbol,
        decimalDigits: digits,
      );
      final formatted = formatter.format(amount);
      if (showCode && !formatted.contains(code)) {
        return '$formatted $code';
      }
      return formatted;
    } catch (_) {
      final formattedNumber = amount.toStringAsFixed(digits);
      return '$symbol$formattedNumber';
    }
  }
}
