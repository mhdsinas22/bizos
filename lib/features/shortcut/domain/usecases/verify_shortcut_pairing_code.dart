import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';

class VerifyShortcutPairingCode {
  final ShortcutRepository shortcutRepository;

  VerifyShortcutPairingCode({required this.shortcutRepository});

  Future<void> verify({required String code}) async {
    await shortcutRepository.verifyPairingCode(code: code);
  }
}
