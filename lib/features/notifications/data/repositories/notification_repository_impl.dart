import 'package:bizos/features/notifications/data/datasource/notifications_remote_datasource.dart';
import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationsRemoteDatasource notificationsRemoteDatasource;
  NotificationRepositoryImpl(this.notificationsRemoteDatasource);
  @override
  Future<void> saveFcmToken(String userId) async {
    return await notificationsRemoteDatasource.saveFcmToken(userId);
  }
}
