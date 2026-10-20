import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';

class SaveShortcutSetupProgress {
  final ShortcutRepository repository;

  SaveShortcutSetupProgress({required this.repository});

  Future<void> call(ShortcutSetupEntity progress) async {
    await repository.saveShortcutSetupProgress(progress);
  }
}
