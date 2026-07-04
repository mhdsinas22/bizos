import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/money_management/domain/usecases/watch_transactions_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/update_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/delete_transaction_usecase.dart';
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
        await addTransactionUseCase.execute(event.transaction, false);
      } catch (e) {
        emit(TransactionsError(e.toString()));
      }
    });

    on<UpdateTransactionEvent>((event, emit) async {
      try {
        await updateTransactionUseCase.execute(event.transaction, false);
      } catch (e) {
        emit(TransactionsError(e.toString()));
      }
    });

    on<DeleteTransactionEvent>((event, emit) async {
      try {
        await deleteTransactionUseCase.execute(event.id, false);
      } catch (e) {
        emit(TransactionsError(e.toString()));
      }
    });
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
