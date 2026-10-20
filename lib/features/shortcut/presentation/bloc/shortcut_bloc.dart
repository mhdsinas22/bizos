import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/shortcut/core/shortcut_constants.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/shortcut/domain/usecases/get_shortcut_setup_status.dart';
import 'package:bizos/features/shortcut/domain/usecases/save_shortcut_setup_progress.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_event.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShortcutBloc extends Bloc<ShortcutEvent, ShortcutState> {
  final ShortcutRepository shortcutRepository;
  final GetShortcutSetupStatus getShortcutSetupStatus;
  final SaveShortcutSetupProgress saveShortcutSetupProgress;

  ShortcutBloc({
    required this.shortcutRepository,
    required this.getShortcutSetupStatus,
    required this.saveShortcutSetupProgress,
  }) : super(const ShortcutState()) {
    on<LoadShortcutSetupStatus>(_onLoadShortcutSetupStatus);
    on<ShortcutStepChanged>(_onShortcutStepChanged);
    on<OpenShortcutsAppRequested>(_onOpenShortcutsAppRequested);
    on<OpenIosSettingsRequested>(_onOpenIosSettingsRequested);
    on<ConfirmShortcutInstalled>(_onConfirmShortcutInstalled);
    on<ConfirmBackTapConfigured>(_onConfirmBackTapConfigured);
    on<TestQuickAddRequested>(_onTestQuickAddRequested);
    on<DismissQuickAddModal>(_onDismissQuickAddModal);
    on<ResetQuickExpenseForm>(_onResetQuickExpenseForm);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<DeepLinkQuickAddReceived>(_onDeepLinkQuickAddReceived);
  }

  Future<void> _onLoadShortcutSetupStatus(
    LoadShortcutSetupStatus event,
    Emitter<ShortcutState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final status = await getShortcutSetupStatus();
      List<String> categories = state.categories;
      if (event.userId.isNotEmpty) {
        categories = await shortcutRepository.getCategories(event.userId);
      }
      final paymentMethods = await shortcutRepository.getPaymentMethods();

      final stepToUse = event.initialStep != null && event.initialStep! > 1
          ? event.initialStep!
          : (state.currentStep > 1 ? state.currentStep : status.currentStep);

      emit(
        state.copyWith(
          isLoading: false,
          currentStep: stepToUse.clamp(
            1,
            ShortcutConstants.totalOnboardingSteps,
          ),
          isShortcutInstalled: status.isShortcutInstalled,
          isBackTapConfigured: status.isBackTapConfigured,
          isCompleted: status.isCompleted,
          categories: categories.isNotEmpty
              ? categories
              : ShortcutConstants.defaultCategories,
          paymentMethods: paymentMethods.isNotEmpty
              ? paymentMethods
              : ShortcutConstants.defaultPaymentMethods,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load shortcut setup status: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load shortcut setup status.',
        ),
      );
    }
  }

  Future<void> _onShortcutStepChanged(
    ShortcutStepChanged event,
    Emitter<ShortcutState> emit,
  ) async {
    final newStep = event.step.clamp(1, ShortcutConstants.totalOnboardingSteps);
    emit(state.copyWith(currentStep: newStep, clearError: true));

    final entity = ShortcutSetupEntity(
      currentStep: newStep,
      isShortcutInstalled: state.isShortcutInstalled,
      isBackTapConfigured: state.isBackTapConfigured,
      isCompleted: state.isCompleted,
    );
    await saveShortcutSetupProgress(entity);
  }

  Future<void> _onOpenShortcutsAppRequested(
    OpenShortcutsAppRequested event,
    Emitter<ShortcutState> emit,
  ) async {
    final url = event.url ?? ShortcutConstants.officialShortcutUrl;
    final opened = await shortcutRepository.openAppleShortcuts(url);
    if (!opened) {
      emit(
        state.copyWith(
          errorMessage:
              'Could not open Apple Shortcuts. Please make sure the Shortcuts app is installed.',
        ),
      );
    }
  }

  Future<void> _onOpenIosSettingsRequested(
    OpenIosSettingsRequested event,
    Emitter<ShortcutState> emit,
  ) async {
    final opened = await shortcutRepository.openIosSettings();
    if (!opened) {
      emit(
        state.copyWith(
          errorMessage:
              'Unable to open Settings automatically. Please open iPhone Settings manually.',
        ),
      );
    }
  }

  Future<void> _onConfirmShortcutInstalled(
    ConfirmShortcutInstalled event,
    Emitter<ShortcutState> emit,
  ) async {
    emit(state.copyWith(isShortcutInstalled: true));
    final entity = ShortcutSetupEntity(
      currentStep: state.currentStep,
      isShortcutInstalled: true,
      isBackTapConfigured: state.isBackTapConfigured,
      isCompleted: state.isCompleted,
    );
    await saveShortcutSetupProgress(entity);
  }

  Future<void> _onConfirmBackTapConfigured(
    ConfirmBackTapConfigured event,
    Emitter<ShortcutState> emit,
  ) async {
    emit(state.copyWith(isBackTapConfigured: true));
    final entity = ShortcutSetupEntity(
      currentStep: state.currentStep,
      isShortcutInstalled: state.isShortcutInstalled,
      isBackTapConfigured: true,
      isCompleted: state.isCompleted,
    );
    await saveShortcutSetupProgress(entity);
  }

  void _onTestQuickAddRequested(
    TestQuickAddRequested event,
    Emitter<ShortcutState> emit,
  ) {
    emit(
      state.copyWith(
        showQuickAddModal: true,
        currentStep: 10,
        clearError: true,
      ),
    );
  }

  void _onDismissQuickAddModal(
    DismissQuickAddModal event,
    Emitter<ShortcutState> emit,
  ) {
    emit(state.copyWith(showQuickAddModal: false));
  }

  void _onResetQuickExpenseForm(
    ResetQuickExpenseForm event,
    Emitter<ShortcutState> emit,
  ) {
    emit(
      state.copyWith(
        expenseStatus: QuickExpenseStatus.initial,
        lastCreatedExpense: null,
        showQuickAddModal: true,
        currentStep: 10,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  Future<void> _onCompleteOnboarding(
    CompleteOnboarding event,
    Emitter<ShortcutState> emit,
  ) async {
    emit(state.copyWith(isCompleted: true, currentStep: 12));
    final entity = ShortcutSetupEntity(
      currentStep: 12,
      isShortcutInstalled: state.isShortcutInstalled,
      isBackTapConfigured: state.isBackTapConfigured,
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    await saveShortcutSetupProgress(entity);
  }

  void _onDeepLinkQuickAddReceived(
    DeepLinkQuickAddReceived event,
    Emitter<ShortcutState> emit,
  ) {
    emit(
      state.copyWith(
        showQuickAddModal: true,
        currentStep: 10,
        initialAmount: event.amount,
        initialCategory: event.category,
        initialNote: event.note,
        initialPaymentMethod: event.paymentMethod,
      ),
    );
  }
}
