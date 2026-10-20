import 'package:equatable/equatable.dart';

abstract class ShortcutFailure extends Equatable {
  final String message;

  const ShortcutFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class InvalidAmountFailure extends ShortcutFailure {
  const InvalidAmountFailure([super.message = 'Please enter a valid amount greater than 0.']);
}

class InvalidCategoryFailure extends ShortcutFailure {
  const InvalidCategoryFailure([super.message = 'Please select a valid expense category.']);
}

class AuthenticationRequiredFailure extends ShortcutFailure {
  const AuthenticationRequiredFailure([super.message = 'You must be signed in to Voryn to add an expense.']);
}

class DuplicateSubmissionFailure extends ShortcutFailure {
  const DuplicateSubmissionFailure([super.message = 'An identical expense is currently being submitted.']);
}

class NetworkFailure extends ShortcutFailure {
  const NetworkFailure([super.message = 'Network error occurred. Please check your connection.']);
}

class ServerFailure extends ShortcutFailure {
  const ServerFailure([super.message = 'Server encountered an error saving the expense.']);
}

class ShortcutPlatformFailure extends ShortcutFailure {
  const ShortcutPlatformFailure([super.message = 'System shortcuts error occurred.']);
}
