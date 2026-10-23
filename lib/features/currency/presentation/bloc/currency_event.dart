import 'package:equatable/equatable.dart';
import 'package:bizos/features/currency/domain/entities/country_entity.dart';

abstract class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => [];
}

class LoadCurrenciesEvent extends CurrencyEvent {}

class SearchCurrenciesEvent extends CurrencyEvent {
  final String query;

  const SearchCurrenciesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCurrencyEvent extends CurrencyEvent {
  final String currencyCode;

  const SelectCurrencyEvent(this.currencyCode);

  @override
  List<Object?> get props => [currencyCode];
}

class LoadCountriesEvent extends CurrencyEvent {}

class SearchCountriesEvent extends CurrencyEvent {
  final String query;

  const SearchCountriesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCountryEvent extends CurrencyEvent {
  final CountryEntity country;

  const SelectCountryEvent(this.country);

  @override
  List<Object?> get props => [country];
}
