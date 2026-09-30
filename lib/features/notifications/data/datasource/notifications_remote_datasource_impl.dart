import 'dart:io';

import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/notifications/data/datasource/notifications_remote_datasource.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsRemoteDatasourceImpl
    implements NotificationsRemoteDatasource {
  final FirebaseMessaging firebaseMessaging;
  final SupabaseClient supabaseClient;
  NotificationsRemoteDatasourceImpl({
    required this.firebaseMessaging,
    required this.supabaseClient,
  });
  @override
  Future<void> saveFcmToken(String userId) async {
    try {
      // 1.Ask permission
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.info("Permission: ${settings.authorizationStatus}");
      AppLogger.info("Sound ${settings.sound}");
      AppLogger.info("Alert ${settings.alert}");
      AppLogger.info("Badge ${settings.badge}");
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token;
        try {
          if (Platform.isIOS) {
            String? apnsToken;
            for (int i = 0; i < 10; i++) {
              apnsToken = await firebaseMessaging.getAPNSToken();

              if (apnsToken != null) {
                break;
              }

              await Future.delayed(const Duration(seconds: 1));
            }
            AppLogger.info("APNS Token:-$apnsToken");
            if (apnsToken == null) {
              AppLogger.warning("APNs token not ready yet");
              return;
            }
          }
          token = await firebaseMessaging.getToken();
          AppLogger.info("FCM Token: $token");
        } catch (apnsError) {
          AppLogger.error("APNs Token not ready or running on iOS Simulator: $apnsError");
        }
        // final userId = supabaseClient.auth.currentUser?.id;
        AppLogger.info(
          "Userid is correwct from check the supbase:-${userId.toString()}",
        );
        if (token != null && userId.isNotEmpty) {
          try {
            await supabaseClient.from("user_fcm_tokens").upsert({
              "user_id": userId,
              "fcm_token": token,
              "created_at": DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: "fcm_token");
            AppLogger.info("FCM Token saved successfully");
          } catch (e) {
            AppLogger.error("notification errr:-${e.toString()}");
          }
        }
      }
    } catch (e) {
      AppLogger.error("notification errr:-${e.toString()}");
    }
  }
}
