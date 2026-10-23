import 'package:equatable/equatable.dart';
import 'package:bizos/features/currency/domain/entities/country_entity.dart';
import 'package:bizos/features/currency/domain/entities/currency_entity.dart';

class CurrencyState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<CurrencyEntity> currencies;
  final List<CurrencyEntity> filteredCurrencies;
  final CurrencyEntity? selectedCurrency;
  final List<CountryEntity> countries;
  final List<CountryEntity> filteredCountries;
  final CountryEntity? selectedCountry;
  final String currencySearchQuery;
  final String countrySearchQuery;
  final String? errorMessage;
  final String? successMessage;

  const CurrencyState({
    this.isLoading = false,
    this.isSaving = false,
    this.currencies = const [],
    this.filteredCurrencies = const [],
    this.selectedCurrency,
    this.countries = const [],
    this.filteredCountries = const [],
    this.selectedCountry,
    this.currencySearchQuery = '',
    this.countrySearchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  CurrencyState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<CurrencyEntity>? currencies,
    List<CurrencyEntity>? filteredCurrencies,
    CurrencyEntity? selectedCurrency,
    List<CountryEntity>? countries,
    List<CountryEntity>? filteredCountries,
    CountryEntity? selectedCountry,
    String? currencySearchQuery,
    String? countrySearchQuery,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CurrencyState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      currencies: currencies ?? this.currencies,
      filteredCurrencies: filteredCurrencies ?? this.filteredCurrencies,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      countries: countries ?? this.countries,
      filteredCountries: filteredCountries ?? this.filteredCountries,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      currencySearchQuery: currencySearchQuery ?? this.currencySearchQuery,
      countrySearchQuery: countrySearchQuery ?? this.countrySearchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    currencies,
    filteredCurrencies,
    selectedCurrency,
    countries,
    filteredCountries,
    selectedCountry,
    currencySearchQuery,
    countrySearchQuery,
    errorMessage,
    successMessage,
  ];
}
