import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  // Legacy User ID lookup
  Future<Map<String, dynamic>?> getUserByUserId(String userId);

  // Supabase Auth sign-in
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  // User profile resolution via auth_user_id
  Future<Map<String, dynamic>?> getUserProfileByAuthId(String authUserId);

  // User profile lookup by email (fallback / verification)
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email);

  // Supabase Auth sign-out
  Future<void> signOut();

  // Current session & user access
  Session? get currentSession;
  User? get currentAuthUser;

  // Update password in Supabase Auth
  Future<UserResponse> updatePassword(String newPassword);

  // Change password flow (verifies old, updates new)
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  );
}
