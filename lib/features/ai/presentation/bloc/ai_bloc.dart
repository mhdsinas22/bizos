import 'package:bizos/features/ai/domain/usecases/ask_ai_usecase.dart';
import 'package:bizos/features/ai/presentation/bloc/ai_event.dart';
import 'package:bizos/features/ai/presentation/bloc/ai_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AskAiUsecase askAiUsecase;
  AiBloc(this.askAiUsecase) : super(AiInitial()) {
    on<AskAiEvent>(_askAI);
  }
  Future<void> _askAI(AskAiEvent event, Emitter<AiState> emit) async {
    try {
      emit(AiLoading());
      final response = await askAiUsecase.call(event.prompt);
      emit(AiLoaded(response: response));
    } catch (e) {
      emit(AiError(error: e.toString()));
    }
  }
}
