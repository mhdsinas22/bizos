import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/personal_expense/presentation/pages/personal_expense_page.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/pages/money_management_dashboard.dart';
import 'package:bizos/features/task/presentation/screens/personal_todo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PersonalParentScreen extends StatefulWidget {
  const PersonalParentScreen({super.key});

  @override
  State<PersonalParentScreen> createState() => _PersonalParentScreenState();
}

class _PersonalParentScreenState extends State<PersonalParentScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<PersonalMoneyManagementBloc>().add(
          WatchTransactionsEvent(userId: userId),
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSegmentTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Top Pill-style Segmented Control Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.scaffoldBackgroundColor,
          child: Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildSegmentItem(
                  0,
                  'To-Do',
                  Icons.check_circle_outline_rounded,
                ),
                _buildSegmentItem(1, 'Expenses', Icons.receipt_long_rounded),
                _buildSegmentItem(
                  2,
                  'Money',
                  Icons.account_balance_wallet_rounded,
                ),
              ],
            ),
          ),
        ),

        // Body Page View with kept state
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (_selectedIndex != index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            physics: const BouncingScrollPhysics(),
            children: const [
              PersonalToDoScreen(),
              PersonalExpensePage(),
              MoneyManagementDashboard(businessId: null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onSegmentTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeIn,
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      primaryColor,
                      Color.lerp(primaryColor, const Color(0xFF3730A3), 0.25) ??
                          primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF334155)),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF334155)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
