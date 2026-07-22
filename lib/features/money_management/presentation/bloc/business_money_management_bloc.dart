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
      emit(TransactionsLoading());
      await _transactionsSubscription?.cancel();
      _transactionsSubscription = watchTransactionsUseCase
          .execute(businessId: event.businessId)
          .listen(
            (transactions) => add(TransactionsUpdatedEvent(transactions)),
            onError: (error) => emit(TransactionsError(error.toString())),
          );
    });

    on<TransactionsUpdatedEvent>((event, emit) {
      emit(TransactionsLoaded(event.transactions));
    });

    on<AddTransactionEvent>((event, emit) async {
      try {
        final createdTransaction = await addTransactionUseCase.execute(event.transaction, false);
        if (state is TransactionsLoaded) {
          final currentList = (state as TransactionsLoaded).transactions;
          final updatedList = List<MoneyTransactionEntity>.from(currentList);
          updatedList.removeWhere((t) => t.id.isEmpty || t.id == createdTransaction.id);
          updatedList.insert(0, createdTransaction);
          emit(TransactionsLoaded(updatedList));
        }
      } catch (e) {
        emit(TransactionsError(e.toString()));
      }
    });

    on<UpdateTransactionEvent>((event, emit) async {
      try {
        await updateTransactionUseCase.execute(event.transaction, false);
        if (state is TransactionsLoaded) {
          final currentList = (state as TransactionsLoaded).transactions;
          final updatedList = currentList.map((t) {
            return t.id == event.transaction.id ? event.transaction : t;
          }).toList();
          emit(TransactionsLoaded(List<MoneyTransactionEntity>.from(updatedList)));
        }
      } catch (e) {
        emit(TransactionsError(e.toString()));
      }
    });

    on<DeleteTransactionEvent>((event, emit) async {
      if (event.id.trim().isEmpty) return;
      final currentState = state;
      try {
        await deleteTransactionUseCase.execute(event.id, false);
        if (currentState is TransactionsLoaded) {
          final currentList = currentState.transactions;
          final updatedList = currentList.where((t) => t.id != event.id).toList();
          emit(TransactionsLoaded(List<MoneyTransactionEntity>.from(updatedList)));
        }
      } catch (e) {
        if (currentState is TransactionsLoaded) {
          // Keep loaded list on deletion error
          emit(currentState);
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
