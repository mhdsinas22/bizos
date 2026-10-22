import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/features/notifications/domain/usecases/save_fcm_token.dart';
import 'package:bizos/features/shortcut/domain/repositories/shortcut_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';
import 'package:bizos/features/auth/domain/usecases/login_usecase.dart';
import 'package:bizos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:bizos/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:bizos/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepo;
  final SaveFcmToken saveFcmTokenUsecase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final ShortcutRepository shortcutRepository;

  AuthBloc({
    required this.authRepo,
    required this.saveFcmTokenUsecase,
    required this.shortcutRepository,
  }) : loginUseCase = LoginUseCase(repository: authRepo),
       logoutUseCase = LogoutUseCase(repository: authRepo),
       checkAuthStatusUseCase = CheckAuthStatusUseCase(repository: authRepo),
       changePasswordUseCase = ChangePasswordUseCase(repository: authRepo),
       super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<ChangePasswordEvent>(_onChangePassword);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase.execute(event.email, event.password);
      try {
        final token = await shortcutRepository.getToken();
        if (token == null || token.isEmpty) {
          await shortcutRepository.provisionShortcutToken(
            deviceName: "Voryn Ios",
          );
        }
      } catch (e) {
        AppLogger.error("Failed to provision shortcut token: $e");
      }
      emit(AuthAuthenticated(user));
      _saveFcmToken(user.id);
    } on AppAuthException catch (e) {
      AppLogger.error("BLOC AUTH EXCEPTION: ${e.message}");
      final requireContact =
          e is UserNotFoundException ||
          e is AccountInactiveException ||
          e is UserNotAuthorizedException;
      emit(AuthError(e.message, isContactOwnerRequired: requireContact));
    } catch (e) {
      AppLogger.error("BLOC CATCH: $e");
      emit(AuthError(e.toString().replaceAll('Exception:', '').trim()));
      AppLogger.error("ERROR STATE EMITTED");
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await logoutUseCase.execute();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await checkAuthStatusUseCase.execute();
      if (user != null) {
        print("working:-${user.email}");
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state.user;
    emit(AuthLoading(user: currentUser));
    try {
      if (currentUser == null) {
        emit(AuthError('No user signed in.'));
        return;
      }
      final success = await changePasswordUseCase.execute(
        currentUser.email.isNotEmpty ? currentUser.email : currentUser.userId,
        event.oldPassword,
        event.newPassword,
      );
      if (success) {
        await logoutUseCase.execute();
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError('Password change failed.', user: currentUser));
      }
    } catch (e) {
      emit(
        AuthError(
          e.toString().replaceAll('Exception:', '').trim(),
          user: currentUser,
        ),
      );
    }
  }

  void _saveFcmToken(String userid) async {
    try {
      await saveFcmTokenUsecase(userid);
      AppLogger.info("✅ FCM Token saved successfully via AuthBloc");
    } catch (e) {
      AppLogger.error("❌ Failed to save FCM Token in AuthBloc: $e");
    }
  }
}
