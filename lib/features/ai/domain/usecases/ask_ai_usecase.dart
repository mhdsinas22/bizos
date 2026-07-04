import 'package:bizos/features/ai/domain/repositories/ai_repository.dart';

class AskAiUsecase {
  final AiRepository aiRepository;
  AskAiUsecase(this.aiRepository);
  Future<String> call(String prompt) {
    return aiRepository.askAi(prompt);
  }
}
