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
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final ChangePasswordUseCase changePasswordUseCase;

  AuthBloc({required this.authRepo})
    : loginUseCase = LoginUseCase(repository: authRepo),
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
      final user = await loginUseCase.execute(event.userId, event.password);
      emit(AuthAuthenticated(user));
    } on AppAuthException catch (e) {
      print("BLOC AUTH EXCEPTION: ${e.message}");
      final requireContact = e is UserNotFoundException || 
                             e is AccountInactiveException || 
                             e is UserNotAuthorizedException;
      emit(AuthError(e.message, isContactOwnerRequired: requireContact));
    } catch (e) {
      print("BLOC CATCH: $e");
      emit(AuthError(e.toString().replaceAll('Exception:', '').trim()));
      print("ERROR STATE EMITTED");
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
    try {
      final user = await checkAuthStatusUseCase.execute();
      if (user != null) {
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
        currentUser.userId,
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
      emit(AuthError(
        e.toString().replaceAll('Exception:', '').trim(),
        user: currentUser,
      ));
    }
  }
}
