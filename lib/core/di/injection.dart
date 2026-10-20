import 'package:bizos/features/shortcut/presentation/di/shortcut_injection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;
Future<void> setupDependencies() async {
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      iOptions: IOSOptions(groupId: '8X62925YPH.com.voryn.erp'),
    ),
  );

  registerShortcutDependencies(getIt);
}
