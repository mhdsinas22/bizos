import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/entities/google_registration_info.dart';

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
  Future<UserModel?> signInWithGoogle();
  Future<UserModel> completeGoogleRegistration({
    required String name,
    required String phone,
  });
  Future<GoogleRegistrationInfo?> getGoogleRegistrationInfo();
  Stream<dynamic> get onAuthStateChange => const Stream.empty();
}
