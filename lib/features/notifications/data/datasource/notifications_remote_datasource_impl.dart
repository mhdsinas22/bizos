import 'dart:io';

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
            print("APNS Token:-$apnsToken");
            if (apnsToken == null) {
              print("APNs token not ready yet");
              return;
            }
          }
          token = await firebaseMessaging.getToken();
          print("FCM Token: $token");
        } catch (apnsError) {
          print("APNs Token not ready or running on iOS Simulator: $apnsError");
        }
        // final userId = supabaseClient.auth.currentUser?.id;
        print(
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
            print("FCM Token saved successfully");
          } catch (e) {
            print("notification errr:-${e.toString()}");
          }
        }
      }
    } catch (e) {
      print("notification errr:-${e.toString()}");
    }
  }
}
