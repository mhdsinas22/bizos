import 'package:bizos/features/ai/data/datasource/ai_remote_datasocure.dart';
import 'package:bizos/features/ai/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDatasocure remoteDatasocure;
  AiRepositoryImpl(this.remoteDatasocure);
  @override
  Future<String> askAi(String prompt) {
    return remoteDatasocure.askAi(prompt);
  }
}
