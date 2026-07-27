import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';

class SaveFcmToken {
  final NotificationRepository repository;
  SaveFcmToken(this.repository);
  Future<void> call(String userId) async {
    return await repository.saveFcmToken(userId);
  }
}
