import 'package:flutter/material.dart';

class PaymentMethodHelper {
  static const String defaultMethod = 'Cash';

  static const List<String> allowedMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Credit Card',
    'Debit Card',
    'Cheque',
    'Wallet',
    'Other',
  ];

  static String sanitize(String? method) {
    if (method == null || method.trim().isEmpty) {
      return defaultMethod;
    }
    final trimmed = method.trim();
    // Case-insensitive match check to preserve exact allowed string capitalization
    for (final allowed in allowedMethods) {
      if (allowed.toLowerCase() == trimmed.toLowerCase()) {
        return allowed;
      }
    }
    return defaultMethod;
  }

  static IconData getIcon(String? method) {
    final sanitized = sanitize(method);
    switch (sanitized) {
      case 'Cash':
        return Icons.payments_outlined;
      case 'UPI':
        return Icons.qr_code_scanner;
      case 'Bank Transfer':
        return Icons.account_balance_outlined;
      case 'Credit Card':
        return Icons.credit_card_outlined;
      case 'Debit Card':
        return Icons.credit_card;
      case 'Cheque':
        return Icons.assignment_outlined;
      case 'Wallet':
        return Icons.account_balance_wallet_outlined;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.payments_outlined;
    }
  }
}
