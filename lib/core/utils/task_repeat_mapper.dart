/// Centralized mapper for Task repeat values.
/// Guarantees strict compliance with PostgreSQL CHECK constraint "tasks_repeat_check":
/// repeat MUST be one of: 'none', 'daily', 'weekly', 'monthly', 'yearly'.
class TaskRepeatMapper {
  TaskRepeatMapper._();

  static const String none = 'none';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  static const String uiNoRepeat = 'No Repeat';
  static const String uiDaily = 'Daily';
  static const String uiWeekly = 'Weekly';
  static const String uiMonthly = 'Monthly';
  static const String uiYearly = 'Yearly';

  /// Valid database values accepted by PostgreSQL check constraint
  static const List<String> validDbValues = [
    none,
    daily,
    weekly,
    monthly,
    yearly,
  ];

  /// User-facing display labels for repeat dropdowns/selectors
  static const List<String> uiOptions = [
    uiNoRepeat,
    uiDaily,
    uiWeekly,
    uiMonthly,
    uiYearly,
  ];

  /// Converts any string (UI label, enum string, raw database string, or legacy format)
  /// into an exact lowercase DB-compliant repeat string ('none', 'daily', 'weekly', 'monthly', 'yearly').
  static String toDb(String? input) {
    if (input == null) return none;
    final clean = input.trim().toLowerCase();

    if (clean == 'daily' || clean == 'repeat.daily' || clean == 'repeattype.daily') {
      return daily;
    }
    if (clean == 'weekly' || clean == 'repeat.weekly' || clean == 'repeattype.weekly') {
      return weekly;
    }
    if (clean == 'monthly' || clean == 'repeat.monthly' || clean == 'repeattype.monthly') {
      return monthly;
    }
    if (clean == 'yearly' || clean == 'repeat.yearly' || clean == 'repeattype.yearly') {
      return yearly;
    }

    // Handles 'none', 'no repeat', 'never', 'all', '', or any unrecognized values
    return none;
  }

  /// Converts a DB repeat value or raw string into user-friendly UI display text
  /// ('No Repeat', 'Daily', 'Weekly', 'Monthly', 'Yearly').
  static String toUi(String? value) {
    final dbValue = toDb(value);
    switch (dbValue) {
      case daily:
        return uiDaily;
      case weekly:
        return uiWeekly;
      case monthly:
        return uiMonthly;
      case yearly:
        return uiYearly;
      case none:
      default:
        return uiNoRepeat;
    }
  }

  /// Returns true if the repeat schedule is recurring (not 'none').
  static bool isRepeating(String? value) {
    return toDb(value) != none;
  }
}
