import 'package:bizos/features/notifications/data/datasource/notifications_remote_datasource.dart';
import 'package:bizos/features/notifications/data/datasource/notifications_remote_datasource_impl.dart';
import 'package:bizos/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:bizos/features/notifications/domain/repositories/notification_repository.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerNotificationDependinces(GetIt getIt) {
  // DataSourcre Remote
  getIt.registerLazySingleton<NotificationsRemoteDatasource>(
    () => NotificationsRemoteDatasourceImpl(
      supabaseClient: getIt<SupabaseClient>(),
      firebaseMessaging: getIt<FirebaseMessaging>(),
    ),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(getIt<NotificationsRemoteDatasource>()),
  );
  getIt.registerLazySingleton<SaveFcmToken>(
    () => SaveFcmToken(getIt<NotificationRepository>()),
  );
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(saveFcmTokenUsecase: getIt<SaveFcmToken>()),
  );
}
