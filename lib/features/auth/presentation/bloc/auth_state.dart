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
  final UserModel user;

  AuthAuthenticated(this.user)
    : super(status: AuthStatus.authenticated, user: user);
}

class AuthUnauthenticated extends AuthState {
  AuthUnauthenticated() : super(status: AuthStatus.unauthenticated);
}

class AuthError extends AuthState {
  final String message;
  final bool isContactOwnerRequired;

  AuthError(this.message, {this.isContactOwnerRequired = false, super.user})
    : super(status: AuthStatus.error, errorMessage: message);
}

// Backward compatibility type aliases
typedef Authenticated = AuthAuthenticated;
typedef Unauthenticated = AuthUnauthenticated;
