import 'package:bizos/features/money_management/domain/entities/money_transaction_entity.dart';
import 'package:equatable/equatable.dart';

abstract class MoneyManagementEvent extends Equatable {
  const MoneyManagementEvent();

  @override
  List<Object?> get props => [];
}

class WatchTransactionsEvent extends MoneyManagementEvent {
  final String? userId;
  final String? businessId;

  const WatchTransactionsEvent({this.userId, this.businessId});

  @override
  List<Object?> get props => [userId, businessId];
}

class TransactionsUpdatedEvent extends MoneyManagementEvent {
  final List<MoneyTransactionEntity> transactions;

  const TransactionsUpdatedEvent(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class AddTransactionEvent extends MoneyManagementEvent {
  final MoneyTransactionEntity transaction;
  final bool isPersonal;

  const AddTransactionEvent(this.transaction, {required this.isPersonal});

  @override
  List<Object?> get props => [transaction, isPersonal];
}

class UpdateTransactionEvent extends MoneyManagementEvent {
  final MoneyTransactionEntity transaction;
  final bool isPersonal;

  const UpdateTransactionEvent(this.transaction, {required this.isPersonal});

  @override
  List<Object?> get props => [transaction, isPersonal];
}

class DeleteTransactionEvent extends MoneyManagementEvent {
  final String id;
  final bool isPersonal;

  const DeleteTransactionEvent(this.id, {required this.isPersonal});

  @override
  List<Object?> get props => [id, isPersonal];
}
