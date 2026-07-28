import 'package:bizos/features/money_management/domain/entities/debt_entity.dart';
import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:equatable/equatable.dart';

abstract class TransactionDetailsEvent extends Equatable {
  const TransactionDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionHistoryEvent extends TransactionDetailsEvent {
  final String transactionId;
  final bool isPersonal;
  final bool isRefresh;
  final String? filterEventType;
  final String? searchQuery;
  final bool ascending;

  const LoadTransactionHistoryEvent({
    required this.transactionId,
    required this.isPersonal,
    this.isRefresh = false,
    this.filterEventType,
    this.searchQuery,
    this.ascending = false,
  });

  @override
  List<Object?> get props => [
    transactionId,
    isPersonal,
    isRefresh,
    filterEventType,
    searchQuery,
    ascending,
  ];
}

class LoadMoreHistoryEvent extends TransactionDetailsEvent {
  final String transactionId;
  final bool isPersonal;

  const LoadMoreHistoryEvent({
    required this.transactionId,
    required this.isPersonal,
  });

  @override
  List<Object?> get props => [transactionId, isPersonal];
}

class AddPaymentEvent extends TransactionDetailsEvent {
  final String transactionId;
  final double amount;
  final String paymentMethod;
  final String notes;
  final bool isPersonal;
  final String? createdBy;

  const AddPaymentEvent({
    required this.transactionId,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
    required this.isPersonal,
    this.createdBy,
  });

  @override
  List<Object?> get props => [
    transactionId,
    amount,
    paymentMethod,
    notes,
    isPersonal,
    createdBy,
  ];
}

class AddAdjustmentEvent extends TransactionDetailsEvent {
  final String transactionId;
  final double amount;
  final String notes;
  final bool isPersonal;
  final String? createdBy;

  const AddAdjustmentEvent({
    required this.transactionId,
    required this.amount,
    required this.notes,
    required this.isPersonal,
    this.createdBy,
  });

  @override
  List<Object?> get props => [
    transactionId,
    amount,
    notes,
    isPersonal,
    createdBy,
  ];
}

class AddReminderEvent extends TransactionDetailsEvent {
  final String transactionId;
  final String notes;
  final bool isPersonal;
  final String? createdBy;

  const AddReminderEvent({
    required this.transactionId,
    required this.notes,
    required this.isPersonal,
    this.createdBy,
  });

  @override
  List<Object?> get props => [transactionId, notes, isPersonal, createdBy];
}

class UpdateHistoryItemEvent extends TransactionDetailsEvent {
  final MoneyTransactionHistoryEntity historyItem;
  final bool isPersonal;

  const UpdateHistoryItemEvent({
    required this.historyItem,
    required this.isPersonal,
  });

  @override
  List<Object?> get props => [historyItem, isPersonal];
}

class DeleteHistoryItemEvent extends TransactionDetailsEvent {
  final String historyId;
  final String transactionId;
  final bool isPersonal;

  const DeleteHistoryItemEvent({
    required this.historyId,
    required this.transactionId,
    required this.isPersonal,
  });

  @override
  List<Object?> get props => [historyId, transactionId, isPersonal];
}

class AddDebtEvent extends TransactionDetailsEvent {
  final DebtEntity debt;
  final bool isPersonal;

  const AddDebtEvent({
    required this.debt,
    required this.isPersonal,
  });

  @override
  List<Object?> get props => [debt, isPersonal];
}

