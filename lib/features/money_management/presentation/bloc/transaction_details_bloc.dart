import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:bizos/features/money_management/domain/usecases/get_transaction_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_payment_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_adjustment_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_reminder_history_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/update_history_item_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/delete_history_item_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_debt_usecase.dart';
import 'package:bizos/features/money_management/presentation/bloc/transaction_details_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/transaction_details_state.dart';

class TransactionDetailsBloc
    extends Bloc<TransactionDetailsEvent, TransactionDetailsState> {
  final GetTransactionHistoryUseCase getTransactionHistoryUseCase;
  final GetTransactionByIdUseCase getTransactionByIdUseCase;
  final AddPaymentHistoryUseCase addPaymentHistoryUseCase;
  final AddAdjustmentHistoryUseCase addAdjustmentHistoryUseCase;
  final AddReminderHistoryUseCase addReminderHistoryUseCase;
  final UpdateHistoryItemUseCase updateHistoryItemUseCase;
  final DeleteHistoryItemUseCase deleteHistoryItemUseCase;
  final AddDebtUseCase addDebtUseCase;

  static const int pageSize = 15;

  TransactionDetailsBloc({
    required this.getTransactionHistoryUseCase,
    required this.getTransactionByIdUseCase,
    required this.addPaymentHistoryUseCase,
    required this.addAdjustmentHistoryUseCase,
    required this.addReminderHistoryUseCase,
    required this.updateHistoryItemUseCase,
    required this.deleteHistoryItemUseCase,
    required this.addDebtUseCase,
  }) : super(TransactionDetailsInitial()) {
    on<LoadTransactionHistoryEvent>(_onLoadHistory);
    on<LoadMoreHistoryEvent>(_onLoadMoreHistory);
    on<AddPaymentEvent>(_onAddPayment);
    on<AddAdjustmentEvent>(_onAddAdjustment);
    on<AddReminderEvent>(_onAddReminder);
    on<UpdateHistoryItemEvent>(_onUpdateHistoryItem);
    on<DeleteHistoryItemEvent>(_onDeleteHistoryItem);
    on<AddDebtEvent>(_onAddDebt);
  }

  Future<void> _onLoadHistory(
    LoadTransactionHistoryEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(TransactionHistoryLoading());
    }

    try {
      final items = await getTransactionHistoryUseCase.execute(
        transactionId: event.transactionId,
        isPersonal: event.isPersonal,
        limit: pageSize,
        offset: 0,
        filterEventType: event.filterEventType,
        searchQuery: event.searchQuery,
        ascending: event.ascending,
      );

      final parentTx = await getTransactionByIdUseCase.execute(
        id: event.transactionId,
        isPersonal: event.isPersonal,
      );

      emit(
        TransactionHistoryLoaded(
          history: items,
          parentTransaction: parentTx,
          hasMore: items.length >= pageSize,
          filterEventType: event.filterEventType ?? 'All',
          searchQuery: event.searchQuery ?? '',
          ascending: event.ascending,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreHistoryEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionHistoryLoaded ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final moreItems = await getTransactionHistoryUseCase.execute(
        transactionId: event.transactionId,
        isPersonal: event.isPersonal,
        limit: pageSize,
        offset: currentState.history.length,
        filterEventType: currentState.filterEventType,
        searchQuery: currentState.searchQuery,
        ascending: currentState.ascending,
      );

      final updatedList = List<MoneyTransactionHistoryEntity>.from(
        currentState.history,
      )..addAll(moreItems);

      emit(
        currentState.copyWith(
          history: updatedList,
          hasMore: moreItems.length >= pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onAddPayment(
    AddPaymentEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    emit(TransactionDetailsActionSubmitting());
    try {
      await addPaymentHistoryUseCase.execute(
        transactionId: event.transactionId,
        amount: event.amount,
        paymentMethod: event.paymentMethod,
        notes: event.notes,
        isPersonal: event.isPersonal,
        createdBy: event.createdBy,
      );

      add(
        LoadTransactionHistoryEvent(
          transactionId: event.transactionId,
          isPersonal: event.isPersonal,
          isRefresh: true,
          filterEventType: currentState is TransactionHistoryLoaded
              ? currentState.filterEventType
              : 'All',
          searchQuery: currentState is TransactionHistoryLoaded
              ? currentState.searchQuery
              : '',
          ascending: currentState is TransactionHistoryLoaded
              ? currentState.ascending
              : false,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }

  Future<void> _onAddAdjustment(
    AddAdjustmentEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    emit(TransactionDetailsActionSubmitting());
    try {
      await addAdjustmentHistoryUseCase.execute(
        transactionId: event.transactionId,
        amount: event.amount,
        notes: event.notes,
        isPersonal: event.isPersonal,
        createdBy: event.createdBy,
      );

      add(
        LoadTransactionHistoryEvent(
          transactionId: event.transactionId,
          isPersonal: event.isPersonal,
          isRefresh: true,
          filterEventType: currentState is TransactionHistoryLoaded
              ? currentState.filterEventType
              : 'All',
          searchQuery: currentState is TransactionHistoryLoaded
              ? currentState.searchQuery
              : '',
          ascending: currentState is TransactionHistoryLoaded
              ? currentState.ascending
              : false,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    emit(TransactionDetailsActionSubmitting());
    try {
      await addReminderHistoryUseCase.execute(
        transactionId: event.transactionId,
        notes: event.notes,
        isPersonal: event.isPersonal,
        createdBy: event.createdBy,
      );

      add(
        LoadTransactionHistoryEvent(
          transactionId: event.transactionId,
          isPersonal: event.isPersonal,
          isRefresh: true,
          filterEventType: currentState is TransactionHistoryLoaded
              ? currentState.filterEventType
              : 'All',
          searchQuery: currentState is TransactionHistoryLoaded
              ? currentState.searchQuery
              : '',
          ascending: currentState is TransactionHistoryLoaded
              ? currentState.ascending
              : false,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }

  Future<void> _onUpdateHistoryItem(
    UpdateHistoryItemEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    emit(TransactionDetailsActionSubmitting());
    try {
      await updateHistoryItemUseCase.execute(
        historyItem: event.historyItem,
        isPersonal: event.isPersonal,
      );

      add(
        LoadTransactionHistoryEvent(
          transactionId: event.historyItem.transactionId,
          isPersonal: event.isPersonal,
          isRefresh: true,
          filterEventType: currentState is TransactionHistoryLoaded
              ? currentState.filterEventType
              : 'All',
          searchQuery: currentState is TransactionHistoryLoaded
              ? currentState.searchQuery
              : '',
          ascending: currentState is TransactionHistoryLoaded
              ? currentState.ascending
              : false,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }

  Future<void> _onDeleteHistoryItem(
    DeleteHistoryItemEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    emit(TransactionDetailsActionSubmitting());
    try {
      await deleteHistoryItemUseCase.execute(
        historyId: event.historyId,
        transactionId: event.transactionId,
        isPersonal: event.isPersonal,
      );

      add(
        LoadTransactionHistoryEvent(
          transactionId: event.transactionId,
          isPersonal: event.isPersonal,
          isRefresh: true,
          filterEventType: currentState is TransactionHistoryLoaded
              ? currentState.filterEventType
              : 'All',
          searchQuery: currentState is TransactionHistoryLoaded
              ? currentState.searchQuery
              : '',
          ascending: currentState is TransactionHistoryLoaded
              ? currentState.ascending
              : false,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }

  Future<void> _onAddDebt(
    AddDebtEvent event,
    Emitter<TransactionDetailsState> emit,
  ) async {
    final currentState = state;
    emit(TransactionDetailsActionSubmitting());
    try {
      final updatedTx = await addDebtUseCase.execute(
        debt: event.debt,
        isPersonal: event.isPersonal,
      );

      emit(const DebtAddedSuccess(message: 'Debt added successfully.'));

      add(
        LoadTransactionHistoryEvent(
          transactionId: updatedTx.id,
          isPersonal: event.isPersonal,
          isRefresh: true,
          filterEventType: currentState is TransactionHistoryLoaded
              ? currentState.filterEventType
              : 'All',
          searchQuery: currentState is TransactionHistoryLoaded
              ? currentState.searchQuery
              : '',
          ascending: currentState is TransactionHistoryLoaded
              ? currentState.ascending
              : false,
        ),
      );
    } catch (e) {
      emit(TransactionDetailsError(e.toString()));
    }
  }
}

