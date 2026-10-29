import 'dart:async';
import 'package:bizos/core/utils/app_logger.dart';
import 'package:bizos/core/utils/currency_formatter.dart';
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
  StreamSubscription<dynamic>? _authSubscription;
  bool _isLoggingOut = false;
  bool _isInGoogleAuthFlow = false;

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
    on<RestoreUserSessionEvent>(_onRestoreUserSession);
    on<ChangePasswordEvent>(_onChangePassword);
    on<UpdateUserCurrencyEvent>(_onUpdateUserCurrency);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<CompleteGoogleRegistrationRequested>(
      _onCompleteGoogleRegistrationRequested,
    );

    _listenToAuthStateChanges();
  }

  void _listenToAuthStateChanges() {
    try {
      _authSubscription = authRepo.onAuthStateChange.listen((data) {
        try {
          final dynamic event = data?.event ?? data;
          AppLogger.info('AuthBloc: onAuthStateChange event received: $event');
          final eventStr = event.toString();
          if (eventStr.contains('signedOut')) {
            if (!_isLoggingOut &&
                !_isInGoogleAuthFlow &&
                state is! GoogleRegistrationRequired &&
                state.status != AuthStatus.unauthenticated) {
              add(LogoutRequested());
            }
          } else if (eventStr.contains('tokenRefreshed')) {
            AppLogger.info('AuthBloc: Token refreshed in background.');
          }
        } catch (e) {
          AppLogger.warning('Error in onAuthStateChange callback: $e');
        }
      });
    } catch (e) {
      AppLogger.warning('Could not subscribe to onAuthStateChange: $e');
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  void _onRestoreUserSession(
    RestoreUserSessionEvent event,
    Emitter<AuthState> emit,
  ) {
    CurrencyFormatter.setCurrency(event.user.currencyCode);
    emit(AuthAuthenticated(event.user));
    _saveFcmToken(event.user.id);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase.execute(event.email, event.password);
      CurrencyFormatter.setCurrency(user.currencyCode);
      try {
        final token = await shortcutRepository.getToken();
        if (token == null || token.isEmpty) {
          await shortcutRepository.provisionShortcutToken(
            deviceName: "Haptic iOS",
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
    if (_isLoggingOut ||
        (state.status == AuthStatus.unauthenticated &&
            state is! GoogleRegistrationRequired)) {
      return;
    }
    _isLoggingOut = true;
    emit(AuthLoading());
    try {
      await logoutUseCase.execute();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    } finally {
      _isLoggingOut = false;
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(user: state.user));
    try {
      final user = await checkAuthStatusUseCase.execute();
      if (user != null) {
        CurrencyFormatter.setCurrency(user.currencyCode);
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } on SessionExpiredException catch (e) {
      AppLogger.warning('Session expired: ${e.message}');
      emit(AuthUnauthenticated(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.warning(
        'Network exception during CheckAuthStatus: ${e.message}',
      );
      if (state.user != null) {
        emit(AuthAuthenticated(state.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      AppLogger.warning('CheckAuthStatus error: $e');
      final err = e.toString().toLowerCase();
      if (err.contains('socketexception') ||
          err.contains('network') ||
          err.contains('connection') ||
          err.contains('timeout')) {
        if (state.user != null) {
          emit(AuthAuthenticated(state.user!));
          return;
        }
      }
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
        _isLoggingOut = true;
        try {
          await logoutUseCase.execute();
        } finally {
          _isLoggingOut = false;
        }
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

  Future<void> _onUpdateUserCurrency(
    UpdateUserCurrencyEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final updatedUser = await authRepo.updateCurrency(event.currencyCode);
      CurrencyFormatter.setCurrency(updatedUser.currencyCode);
      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      AppLogger.error("Failed to update currency in AuthBloc: $e");
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

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    _isInGoogleAuthFlow = true;
    emit(AuthLoading(user: state.user));
    try {
      final user = await authRepo.signInWithGoogle();
      if (user != null) {
        CurrencyFormatter.setCurrency(user.currencyCode);
        await _provisionShortcutToken();
        emit(AuthAuthenticated(user));
        _saveFcmToken(user.id);
        return;
      }

      final details = await authRepo.getGoogleRegistrationInfo();
      if (details == null ||
          details.authUserId.trim().isEmpty ||
          details.email.trim().isEmpty) {
        _isLoggingOut = true;
        try {
          await logoutUseCase.execute();
        } finally {
          _isLoggingOut = false;
        }
        emit(
          AuthError(
            'Unable to retrieve Google account details. Please try signing in again.',
          ),
        );
        return;
      }

      emit(
        GoogleRegistrationRequired(
          authUserId: details.authUserId,
          email: details.email,
          suggestedName: details.suggestedName,
        ),
      );
    } on GoogleSignInCancelledException catch (e) {
      AppLogger.info('Google Sign-In cancelled by user.');
      emit(AuthError(e.message));
    } on AppAuthException catch (e) {
      AppLogger.error('Google Sign-In AuthException: ${e.message}');
      final requireContact =
          e is AccountInactiveException || e is UserNotAuthorizedException;
      emit(AuthError(e.message, isContactOwnerRequired: requireContact));
    } catch (e, stackTrace) {
      AppLogger.error('Google Sign-In Failed: $e\n$stackTrace');
      final cleaned = e
          .toString()
          .replaceAll('Exception:', '')
          .replaceAll('Exception', '')
          .trim();
      emit(
        AuthError(
          cleaned.isNotEmpty
              ? cleaned
              : 'Unable to sign in with Google. Please try again.',
        ),
      );
    } finally {
      _isInGoogleAuthFlow = false;
    }
  }

  Future<void> _onCompleteGoogleRegistrationRequested(
    CompleteGoogleRegistrationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final trimmedName = event.name.trim();
    final trimmedPhone = event.phone.trim();

    if (trimmedName.isEmpty) {
      emit(AuthError('Please enter your full name.'));
      return;
    }
    if (trimmedPhone.isEmpty) {
      emit(AuthError('Please enter your phone number.'));
      return;
    }

    _isInGoogleAuthFlow = true;
    emit(AuthLoading());
    try {
      final user = await authRepo.completeGoogleRegistration(
        name: trimmedName,
        phone: trimmedPhone,
      );
      CurrencyFormatter.setCurrency(user.currencyCode);
      await _provisionShortcutToken();
      emit(AuthAuthenticated(user));
      _saveFcmToken(user.id);
    } on AppAuthException catch (e) {
      AppLogger.error('Google Registration AuthException: ${e.message}');
      emit(AuthError(e.message));
    } catch (e, stackTrace) {
      AppLogger.error('Google Registration Failed: $e\n$stackTrace');
      final cleaned = e
          .toString()
          .replaceAll('Exception:', '')
          .replaceAll('Exception', '')
          .trim();
      emit(
        AuthError(
          cleaned.isNotEmpty
              ? cleaned
              : 'Failed to complete registration. Please try again.',
        ),
      );
    } finally {
      _isInGoogleAuthFlow = false;
    }
  }

  Future<void> _provisionShortcutToken() async {
    try {
      final token = await shortcutRepository.getToken();

      if (token == null || token.isEmpty) {
        await shortcutRepository.provisionShortcutToken(
          deviceName: 'Haptic iOS',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to provision shortcut token: $e');
    }
  }
}
