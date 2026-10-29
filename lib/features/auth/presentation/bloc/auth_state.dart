import 'package:bizos/features/auth/data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

abstract class AuthState {
  final UserModel? user;
  final String? errorMessage;
  final AuthStatus status;

  AuthState({required this.status, this.user, this.errorMessage});
}

class AuthInitial extends AuthState {
  AuthInitial() : super(status: AuthStatus.initial);
}

class AuthLoading extends AuthState {
  AuthLoading({super.user}) : super(status: AuthStatus.loading);
}

class AuthAuthenticated extends AuthState {
  @override
  UserModel get user => super.user!;

  AuthAuthenticated(UserModel user)
    : super(status: AuthStatus.authenticated, user: user);
}

class AuthUnauthenticated extends AuthState {
  AuthUnauthenticated({String? message})
    : super(status: AuthStatus.unauthenticated, errorMessage: message);
}

class AuthError extends AuthState {
  final String message;
  final bool isContactOwnerRequired;

  AuthError(this.message, {this.isContactOwnerRequired = false, super.user})
    : super(status: AuthStatus.error, errorMessage: message);
}

class GoogleRegistrationRequired extends AuthState {
  final String authUserId;
  final String email;
  final String suggestedName;
  GoogleRegistrationRequired({
    required this.authUserId,
    required this.email,
    required this.suggestedName,
  }) : super(status: AuthStatus.unauthenticated);
}

// Backward compatibility type aliases
typedef Authenticated = AuthAuthenticated;
typedef Unauthenticated = AuthUnauthenticated;
