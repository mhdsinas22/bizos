import 'package:get_it/get_it.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/currency/data/datasources/currency_local_datasource.dart';
import 'package:bizos/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:bizos/features/currency/domain/repositories/currency_repository.dart';
import 'package:bizos/features/currency/presentation/bloc/currency_bloc.dart';

void registerCurrencyDependencies(GetIt getIt) {
  getIt.registerLazySingleton<CurrencyLocalDataSource>(
    () => CurrencyLocalDataSourceImpl(),
  );

  getIt.registerLazySingleton<CurrencyRepository>(
    () => CurrencyRepositoryImpl(
      localDataSource: getIt<CurrencyLocalDataSource>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  getIt.registerFactory<CurrencyBloc>(
    () => CurrencyBloc(repository: getIt<CurrencyRepository>()),
  );
}
