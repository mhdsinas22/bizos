import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/money_management/domain/usecases/watch_transactions_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/update_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/delete_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_event.dart';
import 'package:bizos/features/money_management/presentation/bloc/money_management_state.dart';

class BusinessMoneyManagementBloc extends Bloc<MoneyManagementEvent, MoneyManagementState> {
  final WatchTransactionsUseCase watchTransactionsUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;

  StreamSubscription? _transactionsSubscription;

  BusinessMoneyManagementBloc({
    required this.watchTransactionsUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
  }) : super(TransactionsInitial()) {
    on<WatchTransactionsEvent>((event, emit) async {
      if (state is! TransactionsLoaded) {
        emit(TransactionsLoading());
      }
      await _transactionsSubscription?.cancel();
      _transactionsSubscription = watchTransactionsUseCase
          .execute(businessId: event.businessId)
          .listen(
            (transactions) => add(TransactionsUpdatedEvent(transactions)),
            onError: (error) {
              if (state is! TransactionsLoaded) {
                emit(TransactionsError(error.toString()));
              }
            },
          );
    });

    on<TransactionsUpdatedEvent>((event, emit) {
      emit(TransactionsLoaded(List<MoneyTransactionEntity>.from(event.transactions)));
    });

    on<UpsertTransactionLocallyEvent>((event, emit) {
      if (state is TransactionsLoaded) {
        final currentList = List<MoneyTransactionEntity>.from(
          (state as TransactionsLoaded).transactions,
        );
        final index = currentList.indexWhere((t) => t.id == event.transaction.id);
        if (index != -1) {
          currentList[index] = event.transaction;
        } else {
          currentList.insert(0, event.transaction);
        }
        emit(TransactionsLoaded(currentList));
      }
    });

    on<RemoveTransactionLocallyEvent>((event, emit) {
      if (state is TransactionsLoaded) {
        final currentList = List<MoneyTransactionEntity>.from(
          (state as TransactionsLoaded).transactions,
        );
        currentList.removeWhere((t) => t.id == event.id);
        emit(TransactionsLoaded(currentList));
      }
    });

    on<AddTransactionEvent>((event, emit) async {
      // Optimistic in-memory update
      if (state is TransactionsLoaded) {
        final currentList = List<MoneyTransactionEntity>.from(
          (state as TransactionsLoaded).transactions,
        );
        currentList.removeWhere(
          (t) => (event.transaction.id.isNotEmpty && t.id == event.transaction.id),
        );
        currentList.insert(0, event.transaction);
        emit(TransactionsLoaded(currentList));
      }

      try {
        final createdTransaction = await addTransactionUseCase.execute(
          event.transaction,
          false,
        );
        if (state is TransactionsLoaded) {
          final currentList = List<MoneyTransactionEntity>.from(
            (state as TransactionsLoaded).transactions,
          );
          currentList.removeWhere(
            (t) =>
                t.id.isEmpty ||
                t.id == createdTransaction.id ||
                (event.transaction.id.isNotEmpty && t.id == event.transaction.id),
          );
          currentList.insert(0, createdTransaction);
          emit(TransactionsLoaded(currentList));
        }
      } catch (e) {
        if (state is! TransactionsLoaded) {
          emit(TransactionsError(e.toString()));
        }
      }
    });

    on<UpdateTransactionEvent>((event, emit) async {
      if (state is TransactionsLoaded) {
        final currentList = List<MoneyTransactionEntity>.from(
          (state as TransactionsLoaded).transactions,
        );
        final index = currentList.indexWhere((t) => t.id == event.transaction.id);
        if (index != -1) {
          currentList[index] = event.transaction;
          emit(TransactionsLoaded(currentList));
        }
      }

      try {
        await updateTransactionUseCase.execute(event.transaction, false);
      } catch (e) {
        if (state is! TransactionsLoaded) {
          emit(TransactionsError(e.toString()));
        }
      }
    });

    on<DeleteTransactionEvent>((event, emit) async {
      if (event.id.trim().isEmpty) return;
      final previousState = state;
      if (state is TransactionsLoaded) {
        final currentList = List<MoneyTransactionEntity>.from(
          (state as TransactionsLoaded).transactions,
        );
        currentList.removeWhere((t) => t.id == event.id);
        emit(TransactionsLoaded(currentList));
      }

      try {
        await deleteTransactionUseCase.execute(event.id, false);
      } catch (e) {
        if (previousState is TransactionsLoaded) {
          emit(previousState);
        } else {
          emit(TransactionsError(e.toString()));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
