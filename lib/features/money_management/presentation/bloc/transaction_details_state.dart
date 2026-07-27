import 'package:bizos/features/money_management/domain/entities/money_transaction_history_entity.dart';
import 'package:equatable/equatable.dart';

abstract class TransactionDetailsState extends Equatable {
  const TransactionDetailsState();

  @override
  List<Object?> get props => [];
}

class TransactionDetailsInitial extends TransactionDetailsState {}

class TransactionHistoryLoading extends TransactionDetailsState {}

class TransactionHistoryLoaded extends TransactionDetailsState {
  final List<MoneyTransactionHistoryEntity> history;
  final bool hasMore;
  final bool isLoadingMore;
  final String filterEventType;
  final String searchQuery;
  final bool ascending;
  final String? successMessage;

  const TransactionHistoryLoaded({
    required this.history,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.filterEventType = 'All',
    this.searchQuery = '',
    this.ascending = false,
    this.successMessage,
  });

  TransactionHistoryLoaded copyWith({
    List<MoneyTransactionHistoryEntity>? history,
    bool? hasMore,
    bool? isLoadingMore,
    String? filterEventType,
    String? searchQuery,
    bool? ascending,
    String? successMessage,
  }) {
    return TransactionHistoryLoaded(
      history: history ?? this.history,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filterEventType: filterEventType ?? this.filterEventType,
      searchQuery: searchQuery ?? this.searchQuery,
      ascending: ascending ?? this.ascending,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        history,
        hasMore,
        isLoadingMore,
        filterEventType,
        searchQuery,
        ascending,
        successMessage,
      ];
}

class TransactionDetailsActionSubmitting extends TransactionDetailsState {}

class TransactionDetailsError extends TransactionDetailsState {
  final String message;

  const TransactionDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
