import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/currency/domain/entities/country_entity.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_bloc.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_event.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_state.dart';

class CountryPickerSheet extends StatefulWidget {
  final Function(CountryEntity country, String? currencyCode)?
  onCountrySelected;

  const CountryPickerSheet({super.key, this.onCountrySelected});

  static Future<void> show(
    BuildContext context, {
    Function(CountryEntity country, String? currencyCode)? onCountrySelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CurrencyBloc>(),
        child: CountryPickerSheet(onCountrySelected: onCountrySelected),
      ),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<CurrencyBloc>().add(LoadCountriesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCountryTap(CountryEntity country) {
    HapticFeedback.lightImpact();
    if (country.currencyCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${country.name} has no official fiat currency.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (country.currencyCodes.length == 1) {
      final code = country.currencyCodes.first;
      if (widget.onCountrySelected != null) {
        widget.onCountrySelected!(country, code);
      } else {
        context.read<CurrencyBloc>().add(SelectCurrencyEvent(code));
      }
      Navigator.pop(context);
    } else {
      // Multiple currencies (e.g. Panama, Zimbabwe)
      _showMultiCurrencyDialog(country);
    }
  }

  void _showMultiCurrencyDialog(CountryEntity country) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Text(country.flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${country.name} Currencies',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This country supports multiple currencies. Please select one:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...country.currencyCodes.map((code) {
                return ListTile(
                  title: Text(
                    code,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (widget.onCountrySelected != null) {
                      widget.onCountrySelected!(country, code);
                    } else {
                      context.read<CurrencyBloc>().add(
                        SelectCurrencyEvent(code),
                      );
                    }
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Country / Territory',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Worldwide ISO 3166-1 Coverage (250 Countries)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    context.read<CurrencyBloc>().add(SearchCountriesEvent(q));
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by country name, code (e.g. IN, US)...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CurrencyBloc>().add(
                                const SearchCountriesEvent(''),
                              );
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkCard
                        : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Countries List
              Expanded(
                child: BlocBuilder<CurrencyBloc, CurrencyState>(
                  builder: (context, state) {
                    final countries = state.filteredCountries;

                    if (countries.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.public_off_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No countries match "${_searchController.text}"',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: countries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 64, endIndent: 16),
                      itemBuilder: (context, index) {
                        final country = countries[index];
                        final currenciesText = country.currencyCodes.isNotEmpty
                            ? country.currencyCodes.join(', ')
                            : 'No fiat currency';

                        return ListTile(
                          onTap: () => _onCountryTap(country),
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              country.flagEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  country.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  country.code,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Currencies: $currenciesText',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
