import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String sessionBoxName = 'session_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(sessionBoxName);
  }

  static Box _getBox(String boxName) {
    return Hive.box(boxName);
  }

  // Session management
  static Future<void> saveSession(String userId) async {
    final box = _getBox(sessionBoxName);
    await box.put('current_user_id', userId);
  }

  static String? getSessionUserId() {
    final box = _getBox(sessionBoxName);
    return box.get('current_user_id') as String?;
  }

  static Future<void> clearSession() async {
    final box = _getBox(sessionBoxName);
    await box.delete('current_user_id');
     
  }
}
