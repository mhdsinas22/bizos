import 'package:bizos/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> checkAuthStatus();
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  );
  Future<UserModel> updateCurrency(String currencyCode);
  Stream<dynamic> get onAuthStateChange => const Stream.empty();
}

