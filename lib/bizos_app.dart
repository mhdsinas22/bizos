import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/core/theme/theme_bloc.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bizos/features/business/data/datasources/business_remote_datasource_impl.dart';
import 'package:bizos/features/contacts/data/datasoucres/contact_local_datasource_impl.dart';
import 'package:bizos/features/contacts/data/repositories/contact_repositories_impl.dart';
import 'package:bizos/features/contacts/domain/usecases/pick_contact.dart';
import 'package:bizos/features/contacts/presentation/bloc/contact_bloc.dart';
import 'package:bizos/features/finance/data/datasoucre/expense_remote_datasource_impl.dart';
import 'package:bizos/features/finance/data/datasoucre/income_remote_datasource_impl.dart';
import 'package:bizos/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:bizos/features/staff/data/datasource/staff_remote_datasouceimpl.dart';
import 'package:bizos/features/dashboard/data/datasource/dashboard_remote_datasoucre_impl.dart';
import 'package:bizos/features/business/domain/repo/business_repository.dart';
import 'package:bizos/features/business/data/repositories/business_repository_impl.dart';
import 'package:bizos/features/task/data/datasource/task_remote_datasource_impl.dart';
import 'package:bizos/features/task/domain/repositories/task_repository.dart';
import 'package:bizos/features/task/data/repositories/task_repository_impl.dart';
import 'package:bizos/features/finance/domain/repositories/income_repository.dart';
import 'package:bizos/features/finance/data/repositories/income_repository_impl.dart';
import 'package:bizos/features/finance/domain/repositories/expense_repository.dart';
import 'package:bizos/features/finance/data/repositories/expense_repository_impl.dart';
import 'package:bizos/features/staff/domain/repo/staff_repository.dart';
import 'package:bizos/features/staff/data/repo/staff_repository_impl.dart';
import 'package:bizos/features/dashboard/domain/repo/dashboard_repository.dart';
import 'package:bizos/features/dashboard/data/repo/dashboard_repository_impl.dart';
import 'package:bizos/features/reports/data/datasource/report_remote_datasourceimpl.dart';
import 'package:bizos/features/reports/domain/repo/report_repository.dart';
import 'package:bizos/features/reports/data/repo/report_repository_impl.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/login_screen.dart';
import 'package:bizos/features/business/bloc/business_bloc.dart';
import 'package:bizos/features/dashboard/presentation/screens/main_dashboard_screen.dart';
import 'package:bizos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bizos/features/task/presentation/bloc/task_bloc.dart';
import 'package:bizos/features/personal_expense/data/datasource/personal_expense_remote_datasource.dart';
import 'package:bizos/features/personal_expense/domain/repository/personal_expense_repository.dart';
import 'package:bizos/features/personal_expense/data/repository/personal_expense_repository_impl.dart';
import 'package:bizos/features/personal_expense/domain/usecases/add_personal_expense_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/update_personal_expense_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/delete_personal_expense_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/get_personal_expenses_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/get_filtered_expenses_usecase.dart';
import 'package:bizos/features/personal_expense/domain/usecases/get_category_analytics_usecase.dart';
import 'package:bizos/features/personal_expense/presentation/bloc/personal_expense_bloc.dart';
import 'package:bizos/features/ai/data/datasource/ai_remote_datasouce_impl.dart';
import 'package:bizos/features/ai/data/repositories/ai_repository_impl.dart';
import 'package:bizos/features/ai/domain/repositories/ai_repository.dart';
import 'package:bizos/features/ai/domain/usecases/ask_ai_usecase.dart';
import 'package:bizos/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:bizos/features/money_management/data/datasources/money_management_remote_datasource.dart';
import 'package:bizos/features/money_management/domain/repositories/money_management_repository.dart';
import 'package:bizos/features/money_management/data/repositories/money_management_repository_impl.dart';
import 'package:bizos/features/money_management/domain/usecases/watch_transactions_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/add_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/update_transaction_usecase.dart';
import 'package:bizos/features/money_management/domain/usecases/delete_transaction_usecase.dart';
import 'package:bizos/features/money_management/presentation/bloc/personal_money_management_bloc.dart';
import 'package:bizos/features/money_management/presentation/bloc/business_money_management_bloc.dart';
import 'package:bizos/features/activity/data/datasources/activity_remote_datasource.dart';
import 'package:bizos/features/activity/domain/repositories/activity_repository.dart';
import 'package:bizos/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:bizos/features/activity/domain/usecases/get_activities.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:bizos/features/activity/presentation/bloc/activity_event.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BizosApp extends StatelessWidget {
  const BizosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;

    // Data Sources
    final authDatasource = AuthRemoteDataSourceImpl(supabase: supabaseClient);
    final businessDatasource = BusinessRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final taskDatasource = TaskRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final incomeDatasource = IncomeRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final expenseDatasource = ExpenseRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final staffDatasource = StaffRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final dashboardDatasource = DashboardRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final reportDatasource = ReportRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final personalExpenseDatasource = PersonalExpenseRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final moneyManagementDatasource = MoneyManagementRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );
    final activityDatasource = ActivityRemoteDatasourceImpl(
      supabaseClient: supabaseClient,
    );

    final geminiModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: dotenv.env["GEMINI_API_KEY"] ?? "",
    );
    final aiDatasource = AiRemoteDatasouceImpl(geminiModel);

    // Repositories
    final activityRepo = ActivityRepositoryImpl(
      activityRemoteDatasource: activityDatasource,
    );
    final authRepo = AuthRepositoryImpl(authRemoteDataSource: authDatasource);
    final businessRepo = BusinessRepositoryImpl(
      businessRemoteDatasource: businessDatasource,
      activityRepository: activityRepo,
    );
    final taskRepo = TaskRepositoryImpl(
      taskRemoteDatasource: taskDatasource,
      activityRepository: activityRepo,
    );
    final incomeRepo = IncomeRepositoryImpl(
      incomeRemoteDatasource: incomeDatasource,
      activityRepository: activityRepo,
    );
    final expenseRepo = ExpenseRepositoryImpl(
      expenseRemoteDatasource: expenseDatasource,
      activityRepository: activityRepo,
    );
    final staffRepo = StaffRepositoryImpl(
      staffRemoteDatasource: staffDatasource,
      activityRepository: activityRepo,
    );
    final dashboardRepo = DashboardRepositoryImpl(
      dashboardRemoteDatasource: dashboardDatasource,
    );
    final reportRepo = ReportRepositoryImpl(
      reportRemoteDatasource: reportDatasource,
    );
    final personalExpenseRepo = PersonalExpenseRepositoryImpl(
      remoteDataSource: personalExpenseDatasource,
    );
    final moneyManagementRepo = MoneyManagementRepositoryImpl(
      remoteDatasource: moneyManagementDatasource,
      activityRepository: activityRepo,
    );

    final aiRepo = AiRepositoryImpl(aiDatasource);
    final askAiUsecase = AskAiUsecase(aiRepo);
    final contactDatasource = ContactLocalDatasourceImpl();
    final contactRepo = ContactRepositoriesImpl(contactDatasource);
    final pickContactUsecase = PickContact(contactRepo);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ActivityRepository>(create: (_) => activityRepo),
        RepositoryProvider<AuthRepository>(create: (_) => authRepo),
        RepositoryProvider<AiRepository>(create: (_) => aiRepo),
        RepositoryProvider<BusinessRepository>(create: (_) => businessRepo),
        RepositoryProvider<TaskRepository>(create: (_) => taskRepo),
        RepositoryProvider<IncomeRepository>(create: (_) => incomeRepo),
        RepositoryProvider<ExpenseRepository>(create: (_) => expenseRepo),
        RepositoryProvider<StaffRepository>(create: (_) => staffRepo),
        RepositoryProvider<DashboardRepository>(create: (_) => dashboardRepo),
        RepositoryProvider<ReportRepository>(create: (_) => reportRepo),
        RepositoryProvider<PersonalExpenseRepository>(
          create: (_) => personalExpenseRepo,
        ),
        RepositoryProvider<MoneyManagementRepository>(
          create: (_) => moneyManagementRepo,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeBloc>(
            create: (_) => ThemeBloc()..add(LoadThemeEvent()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepo: context.read<AuthRepository>())
                  ..add(CheckAuthEvent()),
          ),
          BlocProvider<BusinessBloc>(
            create: (context) =>
                BusinessBloc(context.read<BusinessRepository>()),
          ),
          BlocProvider<TaskBloc>(
            create: (context) => TaskBloc(
              context.read<TaskRepository>(),
              context.read<AuthBloc>(),
            ),
          ),
          BlocProvider<FinanceBloc>(
            create: (context) => FinanceBloc(
              incomeRepository: context.read<IncomeRepository>(),
              expenseRepository: context.read<ExpenseRepository>(),
            ),
          ),
          BlocProvider<StaffBloc>(
            create: (context) => StaffBloc(context.read<StaffRepository>()),
          ),
          BlocProvider<PersonalExpenseBloc>(
            create: (context) => PersonalExpenseBloc(
              addUseCase: AddPersonalExpenseUseCase(
                repository: context.read<PersonalExpenseRepository>(),
              ),
              updateUseCase: UpdatePersonalExpenseUseCase(
                repository: context.read<PersonalExpenseRepository>(),
              ),
              deleteUseCase: DeletePersonalExpenseUseCase(
                repository: context.read<PersonalExpenseRepository>(),
              ),
              getUseCase: GetPersonalExpensesUseCase(
                repository: context.read<PersonalExpenseRepository>(),
              ),
              getFilteredUseCase: GetFilteredExpensesUseCase(
                repository: context.read<PersonalExpenseRepository>(),
              ),
              getAnalyticsUseCase: GetCategoryAnalyticsUseCase(
                repository: context.read<PersonalExpenseRepository>(),
              ),
            ),
          ),
          BlocProvider<PersonalMoneyManagementBloc>(
            create: (context) => PersonalMoneyManagementBloc(
              watchTransactionsUseCase: WatchTransactionsUseCase(
                context.read<MoneyManagementRepository>(),
              ),
              addTransactionUseCase: AddTransactionUseCase(
                context.read<MoneyManagementRepository>(),
              ),
              updateTransactionUseCase: UpdateTransactionUseCase(
                context.read<MoneyManagementRepository>(),
              ),
              deleteTransactionUseCase: DeleteTransactionUseCase(
                context.read<MoneyManagementRepository>(),
              ),
            ),
          ),
          BlocProvider<BusinessMoneyManagementBloc>(
            create: (context) => BusinessMoneyManagementBloc(
              watchTransactionsUseCase: WatchTransactionsUseCase(
                context.read<MoneyManagementRepository>(),
              ),
              addTransactionUseCase: AddTransactionUseCase(
                context.read<MoneyManagementRepository>(),
              ),
              updateTransactionUseCase: UpdateTransactionUseCase(
                context.read<MoneyManagementRepository>(),
              ),
              deleteTransactionUseCase: DeleteTransactionUseCase(
                context.read<MoneyManagementRepository>(),
              ),
            ),
          ),
          BlocProvider<AiBloc>(create: (context) => AiBloc(askAiUsecase)),
          BlocProvider<ActivityBloc>(
            create: (context) => ActivityBloc(
              getActivities: GetActivities(context.read<ActivityRepository>()),
              authBloc: context.read<AuthBloc>(),
            )..add(FetchActivitiesEvent()),
          ),
          BlocProvider(create: (context) => ContactBloc(pickContactUsecase)),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              title: 'Bizos ERP',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              home: const AppStartupFlow(),
            );
          },
        ),
      ),
    );
  }
}

class AppStartupFlow extends StatelessWidget {
  const AppStartupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    print(dotenv.env['GEMINI_API_KEY']);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.user != null) {
          return const MainDashboardScreen();
        } else if (state.status == AuthStatus.initial) {
          // Loading Screen (Splash)
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    'Loading Bizos Workspace...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
