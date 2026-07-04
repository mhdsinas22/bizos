enum StateStatus { initial, loading, loaded, error }

abstract class AiState {
  final StateStatus status;
  final String? error;
  final String? response;
  AiState({this.status = StateStatus.initial, this.error, this.response});
}

class AiInitial extends AiState {}

class AiLoading extends AiState {
  AiLoading() : super(status: StateStatus.loading);
}

class AiLoaded extends AiState {
  AiLoaded({required String response})
    : super(status: StateStatus.loaded, response: response);
}

class AiError extends AiState {
  AiError({required String error})
    : super(status: StateStatus.error, error: error);
}
