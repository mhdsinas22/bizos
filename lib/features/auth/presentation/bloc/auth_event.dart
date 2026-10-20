abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({String? email, String? userId, required this.password})
    : email = (email ?? userId ?? '').trim();

  // Backward compatibility getter
  String get userId => email;
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

// Backward compatibility classes
class LoginEvent extends LoginRequested {
  LoginEvent({super.email, super.userId, required super.password});
}

class LogoutEvent extends LogoutRequested {}

class CheckAuthEvent extends CheckAuthStatus {}

class ChangePasswordEvent extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  ChangePasswordEvent({required this.oldPassword, required this.newPassword});
}
