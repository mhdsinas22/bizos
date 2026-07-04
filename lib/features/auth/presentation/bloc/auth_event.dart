abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String userId;
  final String password;

  LoginRequested({required this.userId, required this.password});
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

// Backward compatibility classes
class LoginEvent extends LoginRequested {
  LoginEvent({required super.userId, required super.password});
}

class LogoutEvent extends LogoutRequested {}

class CheckAuthEvent extends CheckAuthStatus {}

class ChangePasswordEvent extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  ChangePasswordEvent({required this.oldPassword, required this.newPassword});
}
