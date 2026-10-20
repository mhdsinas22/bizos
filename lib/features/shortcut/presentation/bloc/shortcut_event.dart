import 'package:equatable/equatable.dart';

abstract class ShortcutEvent extends Equatable {
  const ShortcutEvent();

  @override
  List<Object?> get props => [];
}

class LoadShortcutSetupStatus extends ShortcutEvent {
  final String userId;
  final int? initialStep;

  const LoadShortcutSetupStatus({required this.userId, this.initialStep});

  @override
  List<Object?> get props => [userId, initialStep];
}

class ShortcutStepChanged extends ShortcutEvent {
  final int step;

  const ShortcutStepChanged(this.step);

  @override
  List<Object?> get props => [step];
}

class OpenShortcutsAppRequested extends ShortcutEvent {
  final String? url;

  const OpenShortcutsAppRequested({this.url});

  @override
  List<Object?> get props => [url];
}

class OpenIosSettingsRequested extends ShortcutEvent {
  const OpenIosSettingsRequested();
}

class ConfirmShortcutInstalled extends ShortcutEvent {
  const ConfirmShortcutInstalled();
}

class ConfirmBackTapConfigured extends ShortcutEvent {
  const ConfirmBackTapConfigured();
}

class TestQuickAddRequested extends ShortcutEvent {
  const TestQuickAddRequested();
}

class DismissQuickAddModal extends ShortcutEvent {
  const DismissQuickAddModal();
}

class SubmitQuickExpense extends ShortcutEvent {
  final double amount;
  final String category;
  final String paymentMethod;
  final String description;
  final DateTime? expenseDate;
  final String userId;

  const SubmitQuickExpense({
    required this.amount,
    required this.category,
    required this.paymentMethod,
    this.description = '',
    this.expenseDate,
    required this.userId,
  });

  @override
  List<Object?> get props => [
        amount,
        category,
        paymentMethod,
        description,
        expenseDate,
        userId,
      ];
}

class ResetQuickExpenseForm extends ShortcutEvent {
  const ResetQuickExpenseForm();
}

class CompleteOnboarding extends ShortcutEvent {
  const CompleteOnboarding();
}

class DeepLinkQuickAddReceived extends ShortcutEvent {
  final double? amount;
  final String? category;
  final String? note;
  final String? paymentMethod;

  const DeepLinkQuickAddReceived({
    this.amount,
    this.category,
    this.note,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [amount, category, note, paymentMethod];
}
