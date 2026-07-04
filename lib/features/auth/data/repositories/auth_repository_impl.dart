import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizos/core/exceptions/auth_exceptions.dart';
import 'package:bizos/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bizos/features/auth/data/models/user_model.dart';
import 'package:bizos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  static const String _userKey = 'logged_in_user';

  AuthRepositoryImpl({required this.authRemoteDataSource});

  @override
  Future<UserModel> login(String userId, String password) async {
    try {
      final response = await authRemoteDataSource.getUserByUserId(userId);

      if (response == null) {
        throw UserNotFoundException();
      }

      if (response['password'] != password) {
        throw InvalidPasswordException();
      }

      final status = response['status']?.toString().toLowerCase();
      final isActive = response['is_active'];
      if (status == 'inactive' || isActive == false) {
        throw AccountInactiveException();
      }

      final userModel = UserModel.fromJson(response);

      // Store logged-in user locally using SharedPreferences (Requirement 8)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(userModel.toJson()));

      return userModel;
    } on AppAuthException {
      rethrow;
    } on SocketException {
      throw NetworkException();
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') ||
          errorStr.contains('clientexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection') ||
          errorStr.contains('network')) {
        throw NetworkException();
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<UserModel?> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson == null) return null;
      return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      return await authRemoteDataSource.changePassword(
        userId,
        oldPassword,
        newPassword,
      );
    } on SocketException {
      throw Exception('Network Error');
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('ClientException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('connection') ||
          errorStr.contains('Network')) {
        throw Exception('Network Error');
      }
      rethrow;
    }
  }
}
