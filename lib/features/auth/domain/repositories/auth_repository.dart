import 'package:bizos/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String userId, String password);
  Future<void> logout();
  Future<UserModel?> checkAuthStatus();
  Future<bool> changePassword(String userId, String oldPassword, String newPassword);
}
