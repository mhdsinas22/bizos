import 'package:bizos/features/personal_expense/data/datasource/personal_expense_remote_datasource.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_pair_service_remote_datasource.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_pair_service_remote_datasource_impl.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_token_local_datasource.dart';
import 'package:bizos/features/shortcut/data/datasoucre/shortcut_token_local_datasource_impl.dart';
import 'package:bizos/features/shortcut/data/datasources/shortcut_local_datasource.dart';
import 'package:bizos/features/shortcut/data/datasources/shortcut_remote_datasource.dart';
import 'package:bizos/features/shortcut/data/repositories/shortcut_repository_impl.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:bizos/features/shortcut/domain/usecases/get_shortcut_setup_status.dart';
import 'package:bizos/features/shortcut/domain/usecases/pair_shortcut.dart';
import 'package:bizos/features/shortcut/domain/usecases/save_shortcut_setup_progress.dart';
import 'package:bizos/features/shortcut/domain/usecases/verify_shortcut_pairing_code.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_bloc.dart';
import 'package:bizos/features/shortcut/presentation/bloc/shortcut_pair_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void registerShortcutDependencies(GetIt getIt) {
  // Legacy Datasources (for backwards compatibility)
  getIt.registerLazySingleton<ShortcutPairServiceRemoteDatasource>(
    () => ShortcutPairServiceRemoteDatasourceImpl(
      supabaseClient: getIt<SupabaseClient>(),
    ),
  );
  getIt.registerLazySingleton<ShortcutTokenLocalDatasource>(
    () => ShortcutTokenLocalDatasourceImpl(
      flutterSecureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Clean Architecture Datasources
  getIt.registerLazySingleton<ShortcutLocalDatasource>(
    () => ShortcutLocalDatasourceImpl(
      flutterSecureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  getIt.registerLazySingleton<ShortcutRemoteDatasource>(
    () => ShortcutRemoteDatasourceImpl(
      supabaseClient: getIt<SupabaseClient>(),
      personalExpenseRemoteDatasource: PersonalExpenseRemoteDatasourceImpl(
        supabaseClient: getIt<SupabaseClient>(),
      ),
    ),
  );

  // Repository
  getIt.registerLazySingleton<ShortcutRepository>(
    () => ShortcutRepositoryImpl(
      shortcutRemoteDatasource: getIt<ShortcutRemoteDatasource>(),
      shortcutLocalDatasource: getIt<ShortcutLocalDatasource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<PairShortcut>(
    () => PairShortcut(shortcutRepository: getIt<ShortcutRepository>()),
  );
  getIt.registerLazySingleton<VerifyShortcutPairingCode>(
    () => VerifyShortcutPairingCode(
      shortcutRepository: getIt<ShortcutRepository>(),
    ),
  );
  getIt.registerLazySingleton<GetShortcutSetupStatus>(
    () => GetShortcutSetupStatus(repository: getIt<ShortcutRepository>()),
  );
  getIt.registerLazySingleton<SaveShortcutSetupProgress>(
    () => SaveShortcutSetupProgress(repository: getIt<ShortcutRepository>()),
  );

  // BLoCs
  getIt.registerFactory<ShortcutPairBloc>(
    () => ShortcutPairBloc(
      pairShortcut: getIt<PairShortcut>(),
      verifyShortcutPairingCode: getIt<VerifyShortcutPairingCode>(),
    ),
  );

  getIt.registerFactory<ShortcutBloc>(
    () => ShortcutBloc(
      shortcutRepository: getIt<ShortcutRepository>(),
      getShortcutSetupStatus: getIt<GetShortcutSetupStatus>(),
      saveShortcutSetupProgress: getIt<SaveShortcutSetupProgress>(),
    ),
  );
}
