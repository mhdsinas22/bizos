class TransactionEventDetails {
  final String title;
  final String description;

  const TransactionEventDetails({
    required this.title,
    required this.description,
  });
}

class TransactionEventMapper {
  /// Returns both module-aware title and description for a transaction event type.
  static TransactionEventDetails getEventDetails(
    String eventType, {
    required String transactionType,
    String? notes,
  }) {
    return TransactionEventDetails(
      title: formatEventTitle(eventType, transactionType: transactionType),
      description: formatEventDescription(
        eventType,
        transactionType: transactionType,
        notes: notes,
      ),
    );
  }

  /// Returns the module-aware user-facing title for a transaction event type.
  ///
  /// **Money To Pay** (`transactionType == 'pay'`):
  /// - `debt_created` -> Debt Created
  /// - `debt_added` -> Debt Added
  /// - `payment` -> Payment Made
  /// - `payment_updated` -> Payment Updated
  /// - `payment_deleted` -> Payment Removed
  /// - `adjustment` -> Adjustment
  /// - `reminder_sent` -> Reminder Sent
  /// - `status_changed` -> Status Changed
  ///
  /// **Money To Receive** (`transactionType == 'receive'`):
  /// - `debt_created` -> Receivable Created
  /// - `debt_added` -> Receivable Added
  /// - `payment` -> Collection Received
  /// - `payment_updated` -> Collection Updated
  /// - `payment_deleted` -> Collection Removed
  /// - `adjustment` -> Adjustment
  /// - `reminder_sent` -> Reminder Sent
  /// - `status_changed` -> Status Changed
  static String formatEventTitle(
    String eventType, {
    required String transactionType,
  }) {
    final isPay = transactionType == 'pay';
    switch (eventType) {
      case 'debt_created':
        return isPay ? 'Debt Created' : 'Receivable Created';
      case 'debt_added':
        return isPay ? 'Debt Added' : 'Receivable Added';
      case 'payment':
        return isPay ? 'Payment Made' : 'Collection Received';
      case 'payment_updated':
        return isPay ? 'Payment Updated' : 'Collection Updated';
      case 'payment_deleted':
        return isPay ? 'Payment Removed' : 'Collection Removed';
      case 'adjustment':
        return 'Adjustment';
      case 'reminder_sent':
        return 'Reminder Sent';
      case 'status_changed':
        return 'Status Changed';
      default:
        return eventType.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Returns the module-aware user-facing description for a transaction event type.
  ///
  /// **Money To Pay** (`transactionType == 'pay'`):
  /// - `debt_created` -> New debt created.
  /// - `debt_added` -> Additional debt added.
  /// - `payment` -> Payment recorded.
  ///
  /// **Money To Receive** (`transactionType == 'receive'`):
  /// - `debt_created` -> New receivable created.
  /// - `debt_added` -> Additional receivable added.
  /// - `payment` -> Payment collected from customer.
  static String formatEventDescription(
    String eventType, {
    required String transactionType,
    String? notes,
  }) {
    final isPay = transactionType == 'pay';
    final trimmedNotes = notes?.trim() ?? '';

    // Check if notes contains legacy default fallback strings or is empty
    final isDefaultOrEmptyNotes =
        trimmedNotes.isEmpty ||
        trimmedNotes.toLowerCase() == 'debt created' ||
        trimmedNotes.toLowerCase() == 'debt added' ||
        trimmedNotes.toLowerCase() == 'initial payment' ||
        trimmedNotes.toLowerCase() == 'receivable created' ||
        trimmedNotes.toLowerCase() == 'receivable added';

    if (!isDefaultOrEmptyNotes) {
      if (!isPay) {
        // Enforce that Money to Receive module never displays "Debt" terminology
        return trimmedNotes
            .replaceAll('Debt Added', 'Receivable Added')
            .replaceAll('Debt Created', 'Receivable Created')
            .replaceAll('debt added', 'receivable added')
            .replaceAll('debt created', 'receivable created')
            .replaceAll('Debt', 'Receivable')
            .replaceAll('debt', 'receivable');
      }
      return trimmedNotes;
    }

    switch (eventType) {
      case 'debt_created':
        return isPay ? 'New debt created.' : 'New receivable created.';
      case 'debt_added':
        return isPay
            ? 'Additional debt added.'
            : 'Additional receivable added.';
      case 'payment':
        return isPay ? 'Payment recorded.' : 'Payment collected.';
      case 'payment_updated':
        return isPay ? 'Payment updated.' : 'Collection updated.';
      case 'payment_deleted':
        return isPay ? 'Payment removed.' : 'Collection removed.';
      case 'adjustment':
        return 'Adjustment recorded.';
      case 'reminder_sent':
        return 'Reminder sent to customer.';
      case 'status_changed':
        return 'Status changed.';
      default:
        return eventType.replaceAll('_', ' ');
    }
  }

  /// Returns user-facing filter dropdown options based on module type.
  static List<String> getFilterOptions({required String transactionType}) {
    final isPay = transactionType == 'pay';
    return [
      'All',
      isPay ? 'Payments' : 'Collections',
      isPay ? 'Debt Created' : 'Receivable Created',
      isPay ? 'Debt Added' : 'Receivable Added',
      'Adjustments',
      'Reminders',
      'Status',
    ];
  }

  /// Maps a user-facing filter label back to the database `event_type` parameter.
  static String mapFilterToEventType(String filterLabel) {
    switch (filterLabel) {
      case 'Payments':
      case 'Collections':
        return 'payment';
      case 'Debt Created':
      case 'Receivable Created':
        return 'debt_created';
      case 'Debt Added':
      case 'Receivable Added':
        return 'debt_added';
      case 'Adjustments':
        return 'adjustment';
      case 'Reminders':
        return 'reminder_sent';
      case 'Status':
        return 'status_changed';
      case 'All':
      default:
        return 'All';
    }
  }

  /// Returns the total principal label based on module type.
  static String getTotalAmountLabel({required String transactionType}) {
    return transactionType == 'pay' ? 'Total Debt' : 'Total Receivable';
  }

  /// Returns the paid/received label based on module type.
  static String getPaidAmountLabel({required String transactionType}) {
    return transactionType == 'pay' ? 'Paid Amount' : 'Received Amount';
  }

  /// Returns the outstanding balance label based on module type.
  static String getBalanceAmountLabel({required String transactionType}) {
    return transactionType == 'pay' ? 'Outstanding' : 'Amount to Receive';
  }

  /// Returns the hero card balance header label based on module type.
  static String getHeroBalanceLabel({required String transactionType}) {
    return transactionType == 'pay'
        ? 'OUTSTANDING BALANCE'
        : 'AMOUNT TO RECEIVE';
  }

  /// Returns the action button label for adding debt/receivable.
  static String getAddTransactionLabel({required String transactionType}) {
    return transactionType == 'pay' ? 'Add Debt' : 'Add Receivable';
  }

  /// Returns the action button label for adding payment/collection.
  static String getPaymentActionLabel({required String transactionType}) {
    return transactionType == 'pay' ? 'Add Payment' : 'Add Collection';
  }

  /// Returns the choice chip label for increasing debt/receivable in adjustment modal.
  static String getIncreaseAdjustmentLabel({required String transactionType}) {
    return transactionType == 'pay'
        ? 'Increase Debt (+)'
        : 'Increase Receivable (+)';
  }
}
