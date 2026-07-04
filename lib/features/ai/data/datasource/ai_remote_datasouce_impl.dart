import 'package:bizos/features/ai/data/datasource/ai_remote_datasocure.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiRemoteDatasouceImpl implements AiRemoteDatasocure {
  final GenerativeModel model;
  AiRemoteDatasouceImpl(this.model);

  @override
  Future<String> askAi(String prompt) async {
    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
