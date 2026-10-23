import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/currency/domain/entities/currency_entity.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_bloc.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_event.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_state.dart';
import 'package:bizos/features/currency/presentation/widgets/country_picker_sheet.dart';
import 'package:bizos/features/currency/presentation/widgets/currency_list_tile.dart';

class CurrencySettingsPage extends StatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  State<CurrencySettingsPage> createState() => _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends State<CurrencySettingsPage> {
  late final TextEditingController _searchController;
  String _selectedFilter = 'All';

  static const List<String> _popularCodes = [
    'INR',
    'USD',
    'EUR',
    'GBP',
    'AED',
    'SAR',
    'JPY',
    'CAD',
    'AUD',
    'SGD',
    'CHF',
    'KWD',
    'QAR',
    'MYR',
    'CNY',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<CurrencyBloc>().add(LoadCurrenciesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CurrencyEntity> _applyFilter(List<CurrencyEntity> currencies) {
    if (_selectedFilter == 'Popular') {
      return currencies.where((c) => _popularCodes.contains(c.code)).toList();
    } else if (_selectedFilter == '0 Decimals') {
      return currencies.where((c) => c.decimalDigits == 0).toList();
    } else if (_selectedFilter == '3 Decimals') {
      return currencies.where((c) => c.decimalDigits == 3).toList();
    }
    return currencies;
  }

  void _onCurrencySelected(BuildContext context, CurrencyEntity currency) {
    context.read<CurrencyBloc>().add(SelectCurrencyEvent(currency.code));
    // Also notify AuthBloc to keep the authenticated UserModel in sync
    context.read<AuthBloc>().add(UpdateUserCurrencyEvent(currency.code));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Currency Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.public_rounded),
            tooltip: 'Browse by Country',
            onPressed: () => CountryPickerSheet.show(
              context,
              onCountrySelected: (country, code) {
                if (code != null) {
                  context.read<CurrencyBloc>().add(SelectCurrencyEvent(code));
                  context.read<AuthBloc>().add(UpdateUserCurrencyEvent(code));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<CurrencyBloc, CurrencyState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(state.successMessage!)),
                  ],
                ),
                backgroundColor: AppTheme.accentColor,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.error,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.currencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final selected = state.selectedCurrency;
          final filteredList = _applyFilter(state.filteredCurrencies);

          return Column(
            children: [
              // Active Currency Hero Card
              if (selected != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppTheme.darkCard,
                                primary.withValues(alpha: 0.18),
                              ]
                            : [Colors.white, primary.withValues(alpha: 0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Large Symbol Badge
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                Color.lerp(
                                      primary,
                                      const Color(0xFF3730A3),
                                      0.25,
                                    ) ??
                                    primary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            selected.symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Active Currency Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ACTIVE CURRENCY',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      selected.code,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selected.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selected.countriesSummary.isNotEmpty
                                    ? '${selected.primaryFlag} ${selected.countriesSummary}'
                                    : 'Worldwide ISO 4217 Currency',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkmark
                        Icon(Icons.verified_rounded, color: primary, size: 26),
                      ],
                    ),
                  ),
                ),

              // Search Input Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    context.read<CurrencyBloc>().add(SearchCurrenciesEvent(q));
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search by currency name, code, symbol, or country...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CurrencyBloc>().add(
                                const SearchCurrenciesEvent(''),
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
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppTheme.darkBorder
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primary, width: 1.5),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'All (${state.currencies.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Popular',
                      'Popular (${_popularCodes.length})',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('0 Decimals', '0 Decimals (JPY, KRW...)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('3 Decimals', '3 Decimals (BHD, KWD...)'),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Currency List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No currencies found for "${_searchController.text}"',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedFilter = 'All');
                                context.read<CurrencyBloc>().add(
                                  const SearchCurrenciesEvent(''),
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset Search & Filters'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final curr = filteredList[index];
                          final isSelected = selected?.code == curr.code;

                          return CurrencyListTile(
                            currency: curr,
                            isSelected: isSelected,
                            onTap: () => _onCurrencySelected(context, curr),
                          );
                        },
                      ),
              ),

              // Preservation of Finance Data Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFFF8FAFC),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Preference only. Changing currency does not convert historical amounts.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : const Color(0xFF475569)),
      ),
      backgroundColor: isDark ? AppTheme.darkCard : const Color(0xFFF1F5F9),
      selectedColor: primary,
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? primary
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          width: 1,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = filterId;
        });
      },
    );
  }
}
