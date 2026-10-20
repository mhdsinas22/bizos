import 'package:bizos/features/shortcut/domain/entities/quick_expense_entity.dart';
import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/shortcut/domain/usecases/create_quick_expense.dart';
import 'package:bizos/features/shortcut/domain/usecases/get_shortcut_setup_status.dart';
import 'package:bizos/features/shortcut/domain/usecases/save_shortcut_setup_progress.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_bloc.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_event.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_state.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeShortcutRepository implements ShortcutRepository {
  ShortcutSetupEntity setupStatus = const ShortcutSetupEntity(currentStep: 1);
  QuickExpenseEntity? lastCreated;
  bool shouldFailCreation = false;

  @override
  Future<QuickExpenseEntity> createQuickExpense(
    QuickExpenseEntity expense,
    String userId,
  ) async {
    if (shouldFailCreation) {
      throw Exception('Server rejected request');
    }
    lastCreated = expense.copyWith(id: 'saved-id-999');
    return lastCreated!;
  }

  @override
  Future<void> deleteToken() async {}

  @override
  Future<List<String>> getCategories(String userId) async =>
      ['Food', 'Travel', 'Shopping'];

  @override
  Future<List<String>> getPaymentMethods() async =>
      ['Cash', 'UPI', 'Credit Card'];

  @override
  Future<ShortcutSetupEntity> getShortcutSetupStatus() async => setupStatus;

  @override
  Future<String?> getToken() async => 'test-token';

  @override
  Future<bool> openAppleShortcuts(String url) async => true;

  @override
  Future<bool> openIosSettings() async => true;

  @override
  Future<Map<String, dynamic>> pairShortCut({required String deviceName}) async =>
      {'pairing_code': 'PAIR123'};

  @override
  Future<void> provisionShortcutToken({required String deviceName}) async {}

  @override
  Future<void> resetShortcutSetupProgress() async {
    setupStatus = const ShortcutSetupEntity(currentStep: 1);
  }

  @override
  Future<void> saveShortcutSetupProgress(ShortcutSetupEntity status) async {
    setupStatus = status;
  }

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> verifyPairingCode({required String code}) async {}
}

void main() {
  late FakeShortcutRepository repository;
  late GetShortcutSetupStatus getShortcutSetupStatus;
  late SaveShortcutSetupProgress saveShortcutSetupProgress;
  late CreateQuickExpense createQuickExpense;
  late ShortcutBloc bloc;

  setUp(() {
    repository = FakeShortcutRepository();
    getShortcutSetupStatus = GetShortcutSetupStatus(repository: repository);
    saveShortcutSetupProgress =
        SaveShortcutSetupProgress(repository: repository);
    createQuickExpense = CreateQuickExpense(repository: repository);

    bloc = ShortcutBloc(
      shortcutRepository: repository,
      getShortcutSetupStatus: getShortcutSetupStatus,
      saveShortcutSetupProgress: saveShortcutSetupProgress,
      createQuickExpense: createQuickExpense,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ShortcutBloc Tests', () {
    test('initial state has default step 1 and initial status', () {
      expect(bloc.state.currentStep, equals(1));
      expect(bloc.state.isShortcutInstalled, isFalse);
      expect(bloc.state.isBackTapConfigured, isFalse);
      expect(bloc.state.expenseStatus, equals(QuickExpenseStatus.initial));
    });

    test('LoadShortcutSetupStatus populates categories and status', () async {
      bloc.add(const LoadShortcutSetupStatus(userId: 'user-1'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ShortcutState>((s) => s.isLoading == true),
          predicate<ShortcutState>(
            (s) =>
                s.isLoading == false &&
                s.categories.contains('Food') &&
                s.paymentMethods.contains('Cash'),
          ),
        ]),
      );
    });

    test('ShortcutStepChanged updates currentStep and persists progress', () async {
      bloc.add(const ShortcutStepChanged(4));
      await expectLater(
        bloc.stream,
        emits(predicate<ShortcutState>((s) => s.currentStep == 4)),
      );
      expect(repository.setupStatus.currentStep, equals(4));
    });

    test('ConfirmShortcutInstalled sets flag and persists', () async {
      bloc.add(const ConfirmShortcutInstalled());
      await expectLater(
        bloc.stream,
        emits(predicate<ShortcutState>((s) => s.isShortcutInstalled == true)),
      );
      expect(repository.setupStatus.isShortcutInstalled, isTrue);
    });

    test('ConfirmBackTapConfigured sets flag and persists', () async {
      bloc.add(const ConfirmBackTapConfigured());
      await expectLater(
        bloc.stream,
        emits(predicate<ShortcutState>((s) => s.isBackTapConfigured == true)),
      );
      expect(repository.setupStatus.isBackTapConfigured, isTrue);
    });

    test('TestQuickAddRequested sets showQuickAddModal to true and step 10', () async {
      bloc.add(const TestQuickAddRequested());
      await expectLater(
        bloc.stream,
        emits(
          predicate<ShortcutState>(
            (s) => s.showQuickAddModal == true && s.currentStep == 10,
          ),
        ),
      );
    });

    test('SubmitQuickExpense successfully saves expense and transitions to step 11', () async {
      bloc.add(
        const SubmitQuickExpense(
          amount: 250.0,
          category: 'Food & Dining',
          paymentMethod: 'Cash',
          description: 'Coffee with team',
          userId: 'user-1',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ShortcutState>(
            (s) => s.expenseStatus == QuickExpenseStatus.submitting,
          ),
          predicate<ShortcutState>(
            (s) =>
                s.expenseStatus == QuickExpenseStatus.success &&
                s.lastCreatedExpense?.id == 'saved-id-999' &&
                s.currentStep == 11 &&
                s.showQuickAddModal == false,
          ),
        ]),
      );
    });

    test('SubmitQuickExpense validates non-positive amounts', () async {
      bloc.add(
        const SubmitQuickExpense(
          amount: 0.0,
          category: 'Food & Dining',
          paymentMethod: 'Cash',
          userId: 'user-1',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ShortcutState>(
            (s) =>
                s.errorMessage != null &&
                s.errorMessage!.contains('greater than 0'),
          ),
        ),
      );
    });

    test('SubmitQuickExpense handles backend failure cleanly', () async {
      repository.shouldFailCreation = true;

      bloc.add(
        const SubmitQuickExpense(
          amount: 500.0,
          category: 'Travel',
          paymentMethod: 'UPI',
          userId: 'user-1',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ShortcutState>(
            (s) => s.expenseStatus == QuickExpenseStatus.submitting,
          ),
          predicate<ShortcutState>(
            (s) =>
                s.expenseStatus == QuickExpenseStatus.failure &&
                s.errorMessage != null,
          ),
        ]),
      );
    });

    test('DeepLinkQuickAddReceived sets initial parameters and opens popup at step 10', () async {
      bloc.add(
        const DeepLinkQuickAddReceived(
          amount: 1500.0,
          category: 'Electronics',
          note: 'Office keyboard',
          paymentMethod: 'Credit Card',
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          predicate<ShortcutState>(
            (s) =>
                s.showQuickAddModal == true &&
                s.currentStep == 10 &&
                s.initialAmount == 1500.0 &&
                s.initialCategory == 'Electronics' &&
                s.initialNote == 'Office keyboard' &&
                s.initialPaymentMethod == 'Credit Card',
          ),
        ),
      );
    });
  });
}
