import 'package:bizos/features/shortcut/core/shortcut_constants.dart';
import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:equatable/equatable.dart';

enum QuickExpenseStatus { initial, submitting, success, failure }

class ShortcutState extends Equatable {
  final int currentStep;
  final bool isShortcutInstalled;
  final bool isBackTapConfigured;
  final bool isCompleted;
  final List<String> categories;
  final List<String> paymentMethods;
  final bool isLoading;
  final QuickExpenseStatus expenseStatus;
  final QuickExpenseEntity? lastCreatedExpense;
  final String? errorMessage;
  final String? successMessage;
  final bool showQuickAddModal;
  final double? initialAmount;
  final String? initialCategory;
  final String? initialNote;
  final String? initialPaymentMethod;

  const ShortcutState({
    this.currentStep = 1,
    this.isShortcutInstalled = false,
    this.isBackTapConfigured = false,
    this.isCompleted = false,
    this.categories = ShortcutConstants.defaultCategories,
    this.paymentMethods = ShortcutConstants.defaultPaymentMethods,
    this.isLoading = false,
    this.expenseStatus = QuickExpenseStatus.initial,
    this.lastCreatedExpense,
    this.errorMessage,
    this.successMessage,
    this.showQuickAddModal = false,
    this.initialAmount,
    this.initialCategory,
    this.initialNote,
    this.initialPaymentMethod,
  });

  bool get isSubmittingExpense =>
      expenseStatus == QuickExpenseStatus.submitting;

  ShortcutState copyWith({
    int? currentStep,
    bool? isShortcutInstalled,
    bool? isBackTapConfigured,
    bool? isCompleted,
    List<String>? categories,
    List<String>? paymentMethods,
    bool? isLoading,
    QuickExpenseStatus? expenseStatus,
    QuickExpenseEntity? lastCreatedExpense,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    bool? showQuickAddModal,
    double? initialAmount,
    String? initialCategory,
    String? initialNote,
    String? initialPaymentMethod,
  }) {
    return ShortcutState(
      currentStep: currentStep ?? this.currentStep,
      isShortcutInstalled: isShortcutInstalled ?? this.isShortcutInstalled,
      isBackTapConfigured: isBackTapConfigured ?? this.isBackTapConfigured,
      isCompleted: isCompleted ?? this.isCompleted,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      expenseStatus: expenseStatus ?? this.expenseStatus,
      lastCreatedExpense: lastCreatedExpense ?? this.lastCreatedExpense,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      showQuickAddModal: showQuickAddModal ?? this.showQuickAddModal,
      initialAmount: initialAmount ?? this.initialAmount,
      initialCategory: initialCategory ?? this.initialCategory,
      initialNote: initialNote ?? this.initialNote,
      initialPaymentMethod:
          initialPaymentMethod ?? this.initialPaymentMethod,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isShortcutInstalled,
        isBackTapConfigured,
        isCompleted,
        categories,
        paymentMethods,
        isLoading,
        expenseStatus,
        lastCreatedExpense,
        errorMessage,
        successMessage,
        showQuickAddModal,
        initialAmount,
        initialCategory,
        initialNote,
        initialPaymentMethod,
      ];
}
