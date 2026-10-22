import 'package:bizos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:bizos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerAuthDependencies(GetIt getIt) {
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabase: getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      authRemoteDataSource: getIt<AuthRemoteDataSource>(),
      shortcutRepository: getIt<ShortcutRepository>(),
    ),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      authRepo: getIt<AuthRepository>(),
      saveFcmTokenUsecase: getIt<SaveFcmToken>(),
      shortcutRepository: getIt<ShortcutRepository>(),
    ),
  );
}
