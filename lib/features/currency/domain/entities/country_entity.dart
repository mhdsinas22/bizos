import 'package:equatable/equatable.dart';

/// Represents a recognized country or territory with ISO 3166-1 codes
/// and its associated ISO 4217 currency codes.
class CountryEntity extends Equatable {
  /// ISO 3166-1 alpha-2 code (e.g., 'IN', 'US', 'FR').
  final String code;

  /// ISO 3166-1 alpha-3 code (e.g., 'IND', 'USA', 'FRA').
  final String codeAlpha3;

  /// Common country name (e.g., 'India', 'United States', 'France').
  final String name;

  /// Official country name (e.g., 'Republic of India').
  final String officialName;

  /// Country flag emoji (e.g., '🇮🇳', '🇺🇸', '🇫🇷').
  final String flagEmoji;

  /// Associated ISO 4217 currency codes (can be empty, 1, or multiple).
  final List<String> currencyCodes;

  const CountryEntity({
    required this.code,
    required this.codeAlpha3,
    required this.name,
    this.officialName = '',
    required this.flagEmoji,
    this.currencyCodes = const [],
  });

  /// Primary currency code if available.
  String? get primaryCurrencyCode =>
      currencyCodes.isNotEmpty ? currencyCodes.first : null;

  /// Precomputed lowercase search text.
  String get searchableText {
    final buffer = StringBuffer();
    buffer.write(code.toLowerCase());
    buffer.write(' ');
    buffer.write(codeAlpha3.toLowerCase());
    buffer.write(' ');
    buffer.write(name.toLowerCase());
    buffer.write(' ');
    buffer.write(officialName.toLowerCase());
    buffer.write(' ');
    for (final curr in currencyCodes) {
      buffer.write(curr.toLowerCase());
      buffer.write(' ');
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
    code,
    codeAlpha3,
    name,
    officialName,
    flagEmoji,
    currencyCodes,
  ];
}
