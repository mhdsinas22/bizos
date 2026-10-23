import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/currency/domain/repositories/currency_repository.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyRepository repository;

  CurrencyBloc({required this.repository}) : super(const CurrencyState()) {
    on<LoadCurrenciesEvent>(_onLoadCurrencies);
    on<SearchCurrenciesEvent>(_onSearchCurrencies);
    on<SelectCurrencyEvent>(_onSelectCurrency);
    on<LoadCountriesEvent>(_onLoadCountries);
    on<SearchCountriesEvent>(_onSearchCountries);
    on<SelectCountryEvent>(_onSelectCountry);
  }

  Future<void> _onLoadCurrencies(
    LoadCurrenciesEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final currencies = repository.getAllCurrencies();
      final countries = repository.getAllCountries();
      final selectedCode = await repository.getSelectedCurrencyCode();

      final selected =
          repository.getCurrencyByCode(selectedCode) ??
          repository.getCurrencyByCode('INR') ??
          (currencies.isNotEmpty ? currencies.first : null);

      emit(
        state.copyWith(
          isLoading: false,
          currencies: currencies,
          filteredCurrencies: currencies,
          selectedCurrency: selected,
          countries: countries,
          filteredCountries: countries,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load currencies: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load currency dataset.',
        ),
      );
    }
  }

  void _onSearchCurrencies(
    SearchCurrenciesEvent event,
    Emitter<CurrencyState> emit,
  ) {
    final filtered = repository.searchCurrencies(event.query);
    emit(
      state.copyWith(
        currencySearchQuery: event.query,
        filteredCurrencies: filtered,
      ),
    );
  }

  Future<void> _onSelectCurrency(
    SelectCurrencyEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    final target = repository.getCurrencyByCode(event.currencyCode);
    if (target == null) return;

    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    try {
      await repository.saveSelectedCurrencyCode(event.currencyCode);
      emit(
        state.copyWith(
          isSaving: false,
          selectedCurrency: target,
          successMessage: 'Currency updated to ${target.name} (${target.code})',
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to save currency: $e');
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to update currency settings.',
        ),
      );
    }
  }

  void _onLoadCountries(LoadCountriesEvent event, Emitter<CurrencyState> emit) {
    final countries = repository.getAllCountries();
    emit(state.copyWith(countries: countries, filteredCountries: countries));
  }

  void _onSearchCountries(
    SearchCountriesEvent event,
    Emitter<CurrencyState> emit,
  ) {
    final filtered = repository.searchCountries(event.query);
    emit(
      state.copyWith(
        countrySearchQuery: event.query,
        filteredCountries: filtered,
      ),
    );
  }

  void _onSelectCountry(SelectCountryEvent event, Emitter<CurrencyState> emit) {
    emit(state.copyWith(selectedCountry: event.country));

    // If country has associated currency, pre-select or filter to it
    if (event.country.currencyCodes.isNotEmpty) {
      final currCode = event.country.currencyCodes.first;
      final curr = repository.getCurrencyByCode(currCode);
      if (curr != null) {
        add(SelectCurrencyEvent(curr.code));
      }
    }
  }
}
