abstract class AiEvent {
  const AiEvent();
}

class AskAiEvent extends AiEvent {
  final String prompt;
  const AskAiEvent({required this.prompt});
}
