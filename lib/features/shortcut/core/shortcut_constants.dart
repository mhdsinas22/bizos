class ShortcutConstants {
  static const String shortcutName = 'Voryn – Quick Add Expense';
  static const String officialShortcutUrl =
      'https://www.icloud.com/shortcuts/d42ffdb54ff047a4a1371df09a751d2e';

  static const String deepLinkScheme = 'voryn';
  static const String deepLinkHostQuickAdd = 'quick-add';
  static const String deepLinkHostQuickExpense = 'quick-expense';

  static const String methodChannelName = 'com.voryn.erp/shortcut_bridge';

  static const int totalOnboardingSteps = 12;

  // Storage Keys
  static const String prefKeySetupStep = 'voryn_shortcut_setup_step';
  static const String prefKeyShortcutInstalled = 'voryn_shortcut_installed';
  static const String prefKeyBackTapConfigured =
      'voryn_shortcut_backtap_configured';
  static const String prefKeySetupCompleted = 'voryn_shortcut_completed';
  static const String prefKeyDeviceName = 'voryn_shortcut_device_name';

  static const String keychainTokenKey = 'voryn_shortcut_token';
  static const String appAccessGroup = '8X62925YPH.com.voryn.erp';

  // Fallback / standard categories
  static const List<String> defaultCategories = [
    'Food',
    'Travel',
    'Fuel',
    'Shopping',
    'Medical',
    'Family',
    'Education',
    'Entertainment',
    'Bills',
    'Investment',
    'Other',
  ];

  // Allowed payment methods matching existing Voryn standard
  static const List<String> defaultPaymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Credit Card',
    'Debit Card',
    'Cheque',
    'Wallet',
    'Other',
  ];

  // Siri Example Phrases
  static const List<String> siriPhrases = [
    'Hey Siri, add expense in Voryn',
    'Hey Siri, log expense in Voryn',
    'Hey Siri, add ₹500 food expense in Voryn',
  ];
}
