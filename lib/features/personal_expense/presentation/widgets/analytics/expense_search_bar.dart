import 'package:bizos/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ExpenseSearchBar extends StatefulWidget {
  final String searchQuery;
  final String selectedSort;
  final Function(String query) onSearchChanged;
  final Function(String sortBy) onSortChanged;

  const ExpenseSearchBar({
    super.key,
    required this.searchQuery,
    required this.selectedSort,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  State<ExpenseSearchBar> createState() => _ExpenseSearchBarState();
}

class _ExpenseSearchBarState extends State<ExpenseSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant ExpenseSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery && _controller.text != widget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortOptions = [
      {'label': 'Newest First', 'value': 'newest'},
      {'label': 'Oldest First', 'value': 'oldest'},
      {'label': 'Highest Amount', 'value': 'highest'},
      {'label': 'Lowest Amount', 'value': 'lowest'},
    ];

    final currentSortLabel = sortOptions.firstWhere(
      (opt) => opt['value'] == widget.selectedSort,
      orElse: () => sortOptions[0],
    )['label']!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: TextField(
                controller: _controller,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by category, details...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            widget.onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sorting Dropdown Button
          PopupMenuButton<String>(
            icon: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort_outlined,
                    color: isDark ? Colors.white70 : Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentSortLabel.split(' ')[0], // just 'Newest', 'Oldest', etc.
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            tooltip: 'Sort Expenses',
            onSelected: widget.onSortChanged,
            itemBuilder: (context) {
              return sortOptions.map((opt) {
                final isSelected = opt['value'] == widget.selectedSort;
                return PopupMenuItem<String>(
                  value: opt['value'],
                  child: Row(
                    children: [
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          color: AppTheme.primaryColor,
                          size: 18,
                        )
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(
                        opt['label']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
