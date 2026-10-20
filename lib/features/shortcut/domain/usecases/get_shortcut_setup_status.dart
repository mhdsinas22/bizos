import 'package:bizos/features/shortcut/domain/entities/shortcut_setup_entity.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';

class GetShortcutSetupStatus {
  final ShortcutRepository repository;

  GetShortcutSetupStatus({required this.repository});

  Future<ShortcutSetupEntity> call() async {
    return await repository.getShortcutSetupStatus();
  }
}
