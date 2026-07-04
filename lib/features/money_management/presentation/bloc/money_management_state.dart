import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:equatable/equatable.dart';

abstract class MoneyManagementState extends Equatable {
  const MoneyManagementState();

  @override
  List<Object?> get props => [];
}

class TransactionsInitial extends MoneyManagementState {}

class TransactionsLoading extends MoneyManagementState {}

class TransactionsLoaded extends MoneyManagementState {
  final List<MoneyTransactionEntity> transactions;

  const TransactionsLoaded(this.transactions);

  // Getters for Pay transactions
  List<MoneyTransactionEntity> get payTransactions =>
      transactions.where((t) => t.transactionType == 'pay').toList();

  // Getters for Receive transactions
  List<MoneyTransactionEntity> get receiveTransactions =>
      transactions.where((t) => t.transactionType == 'receive').toList();

  // Total Pending Amount to Pay
  double get totalPendingPay => payTransactions
      .where((t) => t.status.toLowerCase() == 'pending')
      .fold(0.0, (sum, t) => sum + t.balanceAmount);

  // Total Pending Amount to Receive
  double get totalPendingReceive => receiveTransactions
      .where((t) => t.status.toLowerCase() == 'pending')
      .fold(0.0, (sum, t) => sum + t.balanceAmount);

  // Total Pending Records count to Pay
  int get pendingPayCount => payTransactions
      .where((t) => t.status.toLowerCase() == 'pending')
      .length;

  // Total Pending Records count to Receive
  int get pendingReceiveCount => receiveTransactions
      .where((t) => t.status.toLowerCase() == 'pending')
      .length;

  @override
  List<Object?> get props => [transactions];
}

class TransactionsError extends MoneyManagementState {
  final String message;

  const TransactionsError(this.message);

  @override
  List<Object?> get props => [message];
}
