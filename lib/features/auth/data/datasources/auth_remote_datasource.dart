abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>?> getUserByUserId(String userId);
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  );
}
