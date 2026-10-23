import 'package:equatable/equatable.dart';

/// Represents an active ISO 4217 currency with rich worldwide metadata.
class CurrencyEntity extends Equatable {
  /// ISO 4217 three-letter currency code (e.g., 'INR', 'USD', 'EUR').
  final String code;

  /// Full currency name (e.g., 'Indian Rupee', 'United States Dollar').
  final String name;

  /// Primary currency symbol (e.g., '₹', '$', '€', 'د.إ').
  final String symbol;

  /// Disambiguated symbol or representation (e.g., 'US$', 'CA$', '₹', 'CHF').
  final String disambiguatedSymbol;

  /// Number of decimal digits (precision), e.g., 2 for USD, 0 for JPY, 3 for BHD.
  final int decimalDigits;

  /// Decimal separator character (e.g., '.', ',').
  final String decimalMark;

  /// Thousands grouping separator (e.g., ',', '.', ' ').
  final String thousandsSeparator;

  /// Name of subunit (e.g., 'Cent', 'Paisa').
  final String subunit;

  /// List of countries and territories that use or accept this currency.
  final List<String> countryNames;

  /// List of ISO 3166-1 alpha-2 country codes (e.g., 'IN', 'US').
  final List<String> countryCodes;

  /// List of emoji flags corresponding to associated countries.
  final List<String> countryFlags;

  const CurrencyEntity({
    required this.code,
    required this.name,
    required this.symbol,
    required this.disambiguatedSymbol,
    required this.decimalDigits,
    this.decimalMark = '.',
    this.thousandsSeparator = ',',
    this.subunit = '',
    this.countryNames = const [],
    this.countryCodes = const [],
    this.countryFlags = const [],
  });

  /// Primary flag to display (first associated country flag or a fallback).
  String get primaryFlag => countryFlags.isNotEmpty ? countryFlags.first : '🌐';

  /// Associated countries summarized for display.
  String get countriesSummary {
    if (countryNames.isEmpty) return '';
    if (countryNames.length <= 3) {
      return countryNames.join(', ');
    }
    return '${countryNames.take(2).join(', ')} +${countryNames.length - 2} more';
  }

  /// Full display label (e.g., 'Indian Rupee — INR — ₹').
  String get displayLabel => '$name — $code — $symbol';

  /// Precomputed lowercase search index covering name, code, symbol, and countries.
  String get searchableText {
    final buffer = StringBuffer();
    buffer.write(code.toLowerCase());
    buffer.write(' ');
    buffer.write(name.toLowerCase());
    buffer.write(' ');
    buffer.write(symbol.toLowerCase());
    buffer.write(' ');
    buffer.write(disambiguatedSymbol.toLowerCase());
    buffer.write(' ');
    for (final c in countryNames) {
      buffer.write(c.toLowerCase());
      buffer.write(' ');
    }
    for (final cc in countryCodes) {
      buffer.write(cc.toLowerCase());
      buffer.write(' ');
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    code,
    name,
    symbol,
    disambiguatedSymbol,
    decimalDigits,
    decimalMark,
    thousandsSeparator,
    countryCodes,
  ];
}
