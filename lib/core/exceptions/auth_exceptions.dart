abstract class AppAuthException implements Exception {
  final String message;
  AppAuthException(this.message);

  @override
  String toString() => message;
}

class UserNotFoundException extends AppAuthException {
  UserNotFoundException() : super('User account not found');
}

class InvalidPasswordException extends AppAuthException {
  InvalidPasswordException() : super('Incorrect password');
}

class AccountInactiveException extends AppAuthException {
  AccountInactiveException() : super('Your account has been disabled. Please contact administrator.');
}

class UserNotAuthorizedException extends AppAuthException {
  UserNotAuthorizedException() : super('You are not authorized to access this application.');
}

class NetworkException extends AppAuthException {
  NetworkException() : super('No internet connection. Please check your network.');
}

class ServerException extends AppAuthException {
  ServerException([String message = 'Something went wrong. Please try again.']) : super(message);
}
