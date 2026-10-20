class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);

  @override
  String toString() => message;
}

class UserNotFoundException extends AppAuthException {
  UserNotFoundException([super.message = 'User account not found']);
}

class InvalidPasswordException extends AppAuthException {
  InvalidPasswordException([super.message = 'Incorrect password']);
}

class InvalidCredentialsException extends AppAuthException {
  InvalidCredentialsException([
    super.message = 'Invalid email or password. Please try again.',
  ]);
}

class AccountInactiveException extends AppAuthException {
  AccountInactiveException([
    super.message =
        'Your account has been disabled. Please contact administrator.',
  ]);
}

class UserNotAuthorizedException extends AppAuthException {
  UserNotAuthorizedException([
    super.message = 'You are not authorized to access this application.',
  ]);
}

class NetworkException extends AppAuthException {
  NetworkException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class ServerException extends AppAuthException {
  ServerException([super.message = 'Something went wrong. Please try again.']);
}
