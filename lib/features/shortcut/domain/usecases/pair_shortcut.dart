import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';

class PairShortcut {
  final ShortcutRepository shortcutRepository;
  PairShortcut({required this.shortcutRepository});
  Future<Map<String, dynamic>> pair({required String deviceName}) async {
    return await shortcutRepository.pairShortCut(deviceName: deviceName);
  }
}
